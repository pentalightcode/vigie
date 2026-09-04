"""Fonctions serveur de Vigie.

digest_quotidien : envoie un rappel matin/soir à chaque utilisateur — une
notification PAR DOSSIER ayant des tâches actives (pas un seul résumé global),
pour que chaque notification puisse renvoyer vers le bon dossier dans l'app
(demandé par Tobie le 2026-08-14). S'il n'y a aucun dossier actif du tout, un
rappel générique de "nourrir" le système si aucun dossier n'a été ajouté
depuis 7 jours (sinon le pipeline des rappels s'assèche silencieusement, voir
Notes/2026-08-07-redteam-...).

Chaque envoi est aussi enregistré dans /utilisateurs/{uid}/notifications,
avec le dossierId (pour la navigation) et une répartition par type de tâche,
pour l'écran "Notifications" de l'app — sans ça, les rappels disparaissent
avec la notification système et ne sont plus consultables dans l'app.
"""

import base64
import hmac
import json
import re
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta, timezone
from email.utils import parseaddr

import dns.resolver
import requests
from cryptography.fernet import Fernet
from firebase_admin import auth as firebase_auth, firestore, initialize_app, messaging
from firebase_functions import firestore_fn, https_fn, scheduler_fn
from firebase_functions.params import SecretParam

initialize_app()

# Bénin (WAT, UTC+1, pas de changement d'heure) — heures approximatives
# choisies plutôt qu'un vrai calcul astronomique (décision du 2026-08-07).
_HORAIRE = "0 */3 * * *"
_FUSEAU = "Africa/Porto-Novo"

# Trouvé lors de l'audit du 2026-08-29 (signalé par Tobie : notifications
# "fantômes", quasi jamais reçues sauf vers minuit) : _situation_a_change
# compare une urgence calculée en jours entiers, qui ne change donc qu'une
# fois par 24h, pile au passage à minuit — sur les 8 vérifications
# quotidiennes (toutes les 3h), une seule détectait un changement. Ces deux
# créneaux (9h/18h, les plus proches de "matin/soir" dans la grille
# existante) forcent l'envoi même sans changement de situation, tant qu'il y
# a quelque chose à traiter — la grille _HORAIRE reste inchangée.
_HEURES_RAPPEL_GARANTI = {9, 18}

# --- Connexion Gmail (automatisation) ---------------------------------
# ID client "Application Web" auto-créé par Firebase (voir GoogleSignIn côté
# app, serverClientId). Le secret associé n'est JAMAIS dans ce fichier —
# stocké via `firebase functions:secrets:set`, injecté à l'exécution.
_GOOGLE_CLIENT_ID = "740523786640-pks5j67kshcu9rshgvsvjert7udoe206.apps.googleusercontent.com"
_google_oauth_client_secret = SecretParam("GOOGLE_OAUTH_CLIENT_SECRET")
_token_chiffrement_cle = SecretParam("TOKEN_CHIFFREMENT_CLE")

# Secret pour publier une nouvelle version dans /config/version (voir
# scripts/publier_version.py) — cette machine n'a pas d'identifiants Google
# Cloud (ADC) pour écrire directement dans Firestore avec l'Admin SDK, donc
# la publication passe par cette fonction protégée par secret plutôt que par
# un accès Firestore ouvert (décision du 2026-08-17).
_admin_publication_secret = SecretParam("ADMIN_PUBLICATION_SECRET")

# Groq (résumé + recommandations IA du Bilan, activable par l'utilisateur —
# voir generer_resume_bilan) : vérifié le 2026-08-12 que Groq n'entraîne pas
# sur les données par défaut, même en gratuit. Clé déjà stockée en secret.
_groq_api_key = SecretParam("GROQ_API_KEY")
_URL_GROQ_CHAT = "https://api.groq.com/openai/v1/chat/completions"
# Modèle vérifié le 2026-08-22 sur la documentation officielle Groq (pas
# supposé de mémoire) : "openai/gpt-oss-120b" est leur modèle "flagship"
# qualité/raisonnement (contre llama-3.3-70b-versatile, correct mais pas le
# meilleur — remarque de Tobie qui a bien fait de demander confirmation).
_MODELE_GROQ = "openai/gpt-oss-120b"


@https_fn.on_call(secrets=[_google_oauth_client_secret, _token_chiffrement_cle])
def connecter_gmail(req: https_fn.CallableRequest) -> dict:
    """Échange le code d'autorisation (obtenu côté app) contre un jeton
    d'accès Google, le chiffre, et le stocke — jamais renvoyé au téléphone.

    Plusieurs comptes Google indépendants peuvent être connectés (revu le
    2026-08-21, sur retour de Tobie après test réel) : chaque connexion
    obtient les mêmes 3 scopes en lecture seule (Gmail, Tasks, Calendar),
    l'app ne prédéfinit AUCUN "rôle" par compte — c'était une tentative plus
    tôt le même jour (deux connexions nommées "email"/"agenda") jugée pas
    intuitive à l'usage. C'est l'utilisateur qui choisit lui-même combien de
    comptes connecter (jusqu'à quelques-uns) et peut leur donner un libellé
    personnalisé ensuite dans l'app, purement pour s'y retrouver — ça ne
    change rien à ce que le serveur en fait."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")
    uid = req.auth.uid
    donnees = req.data or {}
    code = donnees.get("code")
    # Fournie par le téléphone (issue de l'authentification Google de base,
    # toujours disponible sans droit supplémentaire) — plus fiable qu'une
    # relecture serveur via /oauth2/v2/userinfo, qui échouait silencieusement
    # (jeton volontairement limité aux scopes Gmail/Tasks/Calendar, sans
    # email/profil) et laissait l'adresse vide tant qu'on ne renommait pas
    # soi-même la connexion (bug trouvé par Tobie le 2026-08-21).
    email_connecte = (donnees.get("email") or "").strip()
    if not code:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Code manquant.")

    reponse = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "code": code,
            "client_id": _GOOGLE_CLIENT_ID,
            "client_secret": _google_oauth_client_secret.value,
            "grant_type": "authorization_code",
        },
        timeout=10,
    )
    if reponse.status_code != 200:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INTERNAL, "Échec de connexion à Google.")

    jetons = reponse.json()
    refresh_token = jetons.get("refresh_token")
    if not refresh_token:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            "Aucun accès durable reçu — déconnecte-toi de Google puis réessaie.",
        )

    fernet = Fernet(_token_chiffrement_cle.value.encode())
    refresh_token_chiffre = fernet.encrypt(refresh_token.encode()).decode()

    ref = firestore.client().collection("utilisateurs").document(uid).collection("connexionsGoogle").document()
    ref.set({
        "refreshTokenChiffre": refresh_token_chiffre,
        "emailConnecte": email_connecte,
        "connecteLe": firestore.SERVER_TIMESTAMP,
        "libelle": "",
    })

    return {"connexionId": ref.id, "emailConnecte": email_connecte}


def _connexions_actives(uid: str) -> list[dict]:
    """Toutes les connexions Google actives de l'utilisateur (0 à plusieurs,
    aucun rôle prédéfini côté serveur — voir connecter_gmail)."""
    docs = (
        firestore.client()
        .collection("utilisateurs")
        .document(uid)
        .collection("connexionsGoogle")
        .stream()
    )
    resultat = []
    for doc in docs:
        data = doc.to_dict() or {}
        if data.get("refreshTokenChiffre"):
            resultat.append({"id": doc.id, **data})
    return resultat


def _echanger_refresh_token(refresh_token_chiffre: str) -> str | None:
    """Déchiffre un jeton de rafraîchissement et l'échange contre un jeton
    d'accès Google valide (courte durée) — None si l'échange échoue (jeton
    révoqué côté Google, par exemple)."""
    fernet = Fernet(_token_chiffrement_cle.value.encode())
    refresh_token = fernet.decrypt(refresh_token_chiffre.encode()).decode()

    reponse = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "refresh_token": refresh_token,
            "client_id": _GOOGLE_CLIENT_ID,
            "client_secret": _google_oauth_client_secret.value,
            "grant_type": "refresh_token",
        },
        timeout=10,
    )
    if reponse.status_code != 200:
        return None
    return reponse.json()["access_token"]


def _revoquer_connexion_google(refresh_token_chiffre: str) -> None:
    """Révoque vraiment l'accès auprès de Google (pas juste "on oublie le
    jeton de notre côté"). Trouvé lors de l'audit du 2026-08-29 : ni
    deconnecter_gmail ni la suppression de compte n'appelaient ça — le
    consentement OAuth restait actif côté Google indéfiniment (Google ne
    l'expire jamais tout seul), donc le jeton chiffré stocké restait
    valide et exploitable même après "déconnexion" côté Vigie. Best-effort
    : un jeton déjà révoqué/expiré ne doit jamais bloquer la suite
    (déconnexion ou suppression de compte doivent réussir dans tous les cas)."""
    try:
        fernet = Fernet(_token_chiffrement_cle.value.encode())
        refresh_token = fernet.decrypt(refresh_token_chiffre.encode()).decode()
        requests.post(
            "https://oauth2.googleapis.com/revoke",
            params={"token": refresh_token},
            timeout=10,
        )
    except Exception as e:  # pylint: disable=broad-except
        print(f"Échec de révocation Google (jeton probablement déjà invalide) : {type(e).__name__}: {e}")


_MAX_EMAILS_CATALOGUE = 500  # plafond d'une seule page Gmail — au-delà, il faudrait paginer sur plusieurs appels.


def _expediteurs_recents_compte(jeton: str) -> dict[str, int]:
    """Catalogue des expéditeurs vus dans les emails récents d'UN compte
    Google — factorisé pour être appelé une fois par compte connecté."""
    entetes = {"Authorization": f"Bearer {jeton}"}
    ids_messages: list[str] = []
    page_token = None
    while len(ids_messages) < _MAX_EMAILS_CATALOGUE:
        params = {"maxResults": min(100, _MAX_EMAILS_CATALOGUE - len(ids_messages))}
        if page_token:
            params["pageToken"] = page_token
        page = requests.get(
            "https://gmail.googleapis.com/gmail/v1/users/me/messages",
            headers=entetes,
            params=params,
            timeout=15,
        ).json()
        ids_messages.extend(m["id"] for m in page.get("messages", []))
        page_token = page.get("nextPageToken")
        if not page_token:
            break

    def _expediteur_de(message_id: str) -> str | None:
        detail = requests.get(
            f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}",
            headers=entetes,
            params={"format": "metadata", "metadataHeaders": "From"},
            timeout=10,
        ).json()
        for entete in detail.get("payload", {}).get("headers", []):
            if entete["name"] == "From":
                _, adresse = parseaddr(entete["value"])
                return adresse.lower() if adresse else None
        return None

    comptage: dict[str, int] = {}
    with ThreadPoolExecutor(max_workers=25) as executor:
        for adresse in executor.map(_expediteur_de, ids_messages):
            if adresse:
                comptage[adresse] = comptage.get(adresse, 0) + 1
    return comptage


@https_fn.on_call(secrets=[_google_oauth_client_secret, _token_chiffrement_cle], timeout_sec=300)
def lister_expediteurs_recents(req: https_fn.CallableRequest) -> dict:
    """Catalogue des expéditeurs présents dans les emails récents de TOUS les
    comptes Google connectés, fusionnés en une seule liste (demandé par
    Tobie le 2026-08-15 : moins de fautes de frappe, et on a déjà l'accès de
    toute façon ; étendu le 2026-08-21 à plusieurs comptes)."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")

    connexions = _connexions_actives(req.auth.uid)
    if not connexions:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.FAILED_PRECONDITION, "Aucun compte Google connecté.")

    comptage_total: dict[str, int] = {}
    for connexion in connexions:
        jeton = _echanger_refresh_token(connexion["refreshTokenChiffre"])
        if jeton is None:
            continue
        for adresse, n in _expediteurs_recents_compte(jeton).items():
            comptage_total[adresse] = comptage_total.get(adresse, 0) + n

    expediteurs = sorted(comptage_total.items(), key=lambda kv: -kv[1])
    return {"expediteurs": [{"email": e, "nombre": n} for e, n in expediteurs]}


@https_fn.on_call(secrets=[_token_chiffrement_cle])
def deconnecter_gmail(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")
    connexion_id = (req.data or {}).get("connexionId")
    if not connexion_id:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "connexionId manquant.")
    ref = firestore.client().collection("utilisateurs").document(req.auth.uid).collection(
        "connexionsGoogle"
    ).document(connexion_id)
    doc = ref.get()
    if doc.exists:
        chiffre = (doc.to_dict() or {}).get("refreshTokenChiffre")
        if chiffre:
            _revoquer_connexion_google(chiffre)
    ref.delete()
    return {"ok": True}


@https_fn.on_call()
def verifier_domaine_email(req: https_fn.CallableRequest) -> dict:
    """Vérifie que le domaine d'une adresse email a bien des serveurs mail
    configurés (enregistrement MX) — attrape les fautes de frappe de domaine.
    Ne peut PAS garantir qu'une boîte précise existe (Gmail et la plupart des
    gros services bloquent volontairement ce genre de sonde) — honnête sur
    cette limite plutôt que de donner un faux sentiment de certitude."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")
    email = ((req.data or {}).get("email") or "").strip()
    if "@" not in email:
        return {"valide": False}
    domaine = email.rsplit("@", 1)[1]
    try:
        dns.resolver.resolve(domaine, "MX", lifetime=5)
        return {"valide": True}
    except (dns.resolver.NXDOMAIN, dns.resolver.NoAnswer):
        return {"valide": False}
    except Exception:  # pylint: disable=broad-except
        # Panne DNS transitoire : on ne bloque pas l'utilisateur pour ça.
        return {"valide": True, "verificationIncertaine": True}


@scheduler_fn.on_schedule(schedule=_HORAIRE, timezone=_FUSEAU)
def digest_quotidien(event: scheduler_fn.ScheduledEvent) -> None:
    """Vérifie plus souvent que ça n'avertit — un rappel n'est envoyé que si
    la situation d'un dossier a vraiment changé depuis le dernier envoi
    (décision du 2026-08-17 : Tobie voulait des vérifications plus
    fréquentes, sans que ça devienne du spam à répéter le même message)."""
    db = firestore.client()
    maintenant = datetime.now(timezone.utc)
    heure_locale = (maintenant.hour + 1) % 24  # Africa/Porto-Novo = UTC+1 fixe
    rappel_garanti = heure_locale in _HEURES_RAPPEL_GARANTI

    for doc_utilisateur in db.collection("utilisateurs").stream():
        uid = doc_utilisateur.id
        token = (doc_utilisateur.to_dict() or {}).get("fcmToken")
        if not token:
            continue

        try:
            for digest in _construire_digests(db, uid, maintenant):
                if not _situation_a_change(db, uid, digest, maintenant) and not rappel_garanti:
                    continue
                _envoyer(uid, token, digest)
                _enregistrer_historique(db, uid, digest)
        except Exception as e:  # pylint: disable=broad-except
            print(f"Échec du digest quotidien pour {uid} : {type(e).__name__}: {e}")


def _palier_urgence(groupe: dict) -> str:
    """Le palier de ton utilisé — sert à décider si la situation a "changé"
    (voir _situation_a_change) même quand total/enRetard restent identiques :
    un retard qui passe de 2 à 3 jours change le ton sans changer les
    chiffres, il faut quand même renotifier."""
    if groupe["enRetard"] > 0:
        pire = groupe["joursRetardMax"]
        if pire >= 8:
            return "critique"
        if pire >= 3:
            return "ferme"
        return "leger"
    jours_avant = groupe["joursAvantMin"]
    if jours_avant is not None and jours_avant <= 2:
        return "proche"
    return "normal"


def _corps_escalade(groupe: dict) -> str:
    """Le ton se durcit avec la proximité/l'ancienneté du retard, au lieu
    d'un message identique à chaque fois — aucune des apps comparées ne
    fait vraiment ça, c'est une vraie carte à jouer pour Vigie (demandé par
    Tobie le 2026-08-20, approfondissement du Red Team)."""
    nom = groupe["nomCodeDossier"]
    total = groupe["total"]
    en_retard = groupe["enRetard"]

    if en_retard > 0:
        base = f"{nom} : {total} tâche(s) à traiter, dont {en_retard} en retard"
        pire = groupe["joursRetardMax"]
        if pire >= 8:
            return f"🔴 {base} depuis {pire} jours — à traiter en priorité."
        if pire >= 3:
            return f"⚠️ {base} depuis {pire} jour(s), ça s'accumule."
        return f"{base}."

    jours_avant = groupe["joursAvantMin"]
    if jours_avant is not None and jours_avant <= 2:
        echeance = "aujourd'hui" if jours_avant == 0 else f"dans {jours_avant} jour(s)"
        return f"{nom} : {total} tâche(s) à traiter, échéance {echeance}."

    return f"{nom} : {total} tâche(s) à traiter."


def _taches_actives_visibles(db, uid: str):
    """Tâches "à faire" visibles par cet utilisateur : les siennes (uid==,
    dossiers dont il est propriétaire) ET celles des dossiers PARTAGÉS dont
    il est participant (participantsUids array-contains) — dédupliquées par
    identifiant de document. Miroir côté serveur de `_filtreParticipant` côté
    app (voir firestore_service.dart).

    Trouvé en continuant la Phase 1 collaboration (2026-08-30) : sans ce
    deuxième filtre, `digest_quotidien` ne cherchait jamais que les tâches
    dont `uid` == le PROPRIÉTAIRE du dossier — un participant ajouté à un
    dossier partagé ne recevait donc jamais aucun rappel pour ses tâches,
    alors que les rappels sont la fonctionnalité centrale de Vigie. Deux
    requêtes séparées plutôt qu'un Filter.or côté Python : les index
    composites nécessaires (uid+statut, participantsUids+statut) existent
    déjà tous les deux dans firestore.indexes.json."""
    par_id: dict[str, dict] = {}
    requetes = [
        db.collection("taches").where("uid", "==", uid).where("statut", "==", "aFaire"),
        db.collection("taches").where("participantsUids", "array_contains", uid).where("statut", "==", "aFaire"),
    ]
    for requete in requetes:
        for doc in requete.stream():
            par_id[doc.id] = doc.to_dict()
    return par_id.values()


def _construire_digests(db, uid: str, maintenant: datetime) -> list[dict]:
    """Un digest par dossier ayant au moins une tâche active — ou, s'il n'y
    en a aucun, un unique rappel générique d'alimentation."""
    par_dossier: dict[str, dict] = {}
    for t in _taches_actives_visibles(db, uid):
        date_premier_rappel = t.get("datePremierRappel")
        if not date_premier_rappel or date_premier_rappel > maintenant:
            continue  # Pas encore active ("en attente").

        dossier_id = t.get("dossierId")
        groupe = par_dossier.setdefault(dossier_id, {
            "dossierId": dossier_id,
            "nomCodeDossier": t.get("nomCodeDossier") or "Dossier",
            "total": 0,
            "enRetard": 0,
            "parType": {},
            "joursRetardMax": 0,
            "joursAvantMin": None,
        })
        groupe["total"] += 1
        nature = t.get("nature") or "Autre"
        groupe["parType"][nature] = groupe["parType"].get(nature, 0) + 1
        date_declenchante = t.get("dateDeclenchante")
        if date_declenchante:
            if date_declenchante < maintenant:
                groupe["enRetard"] += 1
                jours_retard = (maintenant - date_declenchante).days
                groupe["joursRetardMax"] = max(groupe["joursRetardMax"], jours_retard)
            else:
                jours_avant = (date_declenchante - maintenant).days
                if groupe["joursAvantMin"] is None or jours_avant < groupe["joursAvantMin"]:
                    groupe["joursAvantMin"] = jours_avant

    if par_dossier:
        digests = []
        for groupe in par_dossier.values():
            digests.append({**groupe, "corps": _corps_escalade(groupe)})
        return digests

    corps_alimentation = _rappel_alimentation_si_besoin(db, uid, maintenant)
    if corps_alimentation is None:
        return []
    return [{
        "dossierId": None,
        "nomCodeDossier": None,
        "corps": corps_alimentation,
        "parType": {},
        "total": 0,
        "enRetard": 0,
    }]


_DELAI_MIN_ENTRE_RAPPELS_ALIMENTATION = timedelta(hours=20)


def _situation_a_change(db, uid: str, digest: dict, maintenant: datetime) -> bool:
    """True seulement si ce dossier (ou le rappel d'alimentation) a une
    situation différente de la dernière fois qu'on a prévenu — permet de
    vérifier souvent sans jamais répéter le même message pour rien."""
    ref_etats = db.collection("utilisateurs").document(uid).collection("etatsNotifies")

    if digest["dossierId"] is None:
        # Rappel d'alimentation générique : pas de "situation" à comparer,
        # juste un délai minimum entre deux envois pour ne pas le répéter
        # à chaque vérification si la fréquence augmente.
        doc = ref_etats.document("_alimentation").get()
        derniere = (doc.to_dict() or {}).get("envoyeLe") if doc.exists else None
        if derniere and (maintenant - derniere) < _DELAI_MIN_ENTRE_RAPPELS_ALIMENTATION:
            return False
        ref_etats.document("_alimentation").set({"envoyeLe": maintenant})
        return True

    etat_actuel = {
        "total": digest["total"],
        "enRetard": digest["enRetard"],
        "palier": _palier_urgence(digest),
    }
    doc_ref = ref_etats.document(digest["dossierId"])
    doc = doc_ref.get()
    etat_precedent = doc.to_dict() if doc.exists else None
    if etat_precedent == etat_actuel:
        return False
    doc_ref.set(etat_actuel)
    return True


def _rappel_alimentation_si_besoin(db, uid: str, maintenant: datetime) -> str | None:
    dossiers_recents = list(
        db.collection("dossiers")
        .where("uid", "==", uid)
        .order_by("creeLe", direction=firestore.Query.DESCENDING)
        .limit(1)
        .stream()
    )
    if dossiers_recents:
        cree_le = dossiers_recents[0].to_dict().get("creeLe")
        if cree_le and (maintenant - cree_le) < timedelta(days=7):
            return None  # Un dossier a été ajouté récemment, rien à signaler.

    return "Rien à traiter pour l'instant, pense à ajouter des tâches aux dossiers de la semaine."


_CORPS_PUBLIC_PAR_DEFAUT = "Tu as une nouvelle notification dans Vigie."


def _envoyer(uid: str, token: str, digest: dict, lien: str | None = None, corps_public: str | None = None) -> None:
    # Trouvé lors de l'audit de sécurité du 2026-08-29 (demandé par Tobie) :
    # digest["corps"] contient parfois le nom de code du dossier ou l'objet
    # d'un email (voir _corps_escalade et le rappel manuel emails) — hors de
    # question de l'envoyer tel quel à FCM, ce texte s'affiche sur l'écran
    # verrouillé indépendamment du code de l'app (le réglage dépend du
    # téléphone, pas de nous). Par défaut on pousse un message générique ;
    # seuls les appelants qui ont vérifié que leur contenu est sans donnée
    # sensible passent explicitement corps_public. Le détail réel reste
    # disponible dans l'historique in-app (_enregistrer_historique), protégé
    # par l'auth + le verrou PIN.
    corps_affiche = corps_public if corps_public is not None else _CORPS_PUBLIC_PAR_DEFAUT
    data = {"dossierId": digest["dossierId"] or ""}
    if lien:
        # Champ réservé (documenté dans les options "lien" de la console
        # Firebase) : quand présent, le SDK FCM natif d'Android ouvre cette
        # URL directement au clic sur la notification — géré entièrement par
        # Google Play Services, pas par le code de l'app (donc indépendant
        # du souci url_launcher/manifest jamais résolu le 2026-08-17, voir
        # bannière). N'est ajouté que pour les notifications de mise à jour,
        # jamais pour les rappels de dossier normaux.
        data["gcm.n.link"] = lien
    message = messaging.Message(
        notification=messaging.Notification(title="Vigie", body=corps_affiche),
        data=data,
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="rappels_vigie_v2",  # doit matcher notification_service.dart
                sound="default",
                priority="high",
                default_vibrate_timings=True,
                # Défense en profondeur : force le comportement même sur les
                # téléphones dont le réglage écran verrouillé par défaut
                # afficherait tout le contenu.
                visibility="private",
            ),
        ),
        token=token,
    )
    try:
        messaging.send(message)
    except messaging.UnregisteredError:
        # Le token n'est plus valide (app désinstallée, etc.) — on le retire
        # pour ne pas réessayer indéfiniment à chaque digest.
        firestore.client().collection("utilisateurs").document(uid).update(
            {"fcmToken": firestore.DELETE_FIELD}
        )
    except Exception as e:  # pylint: disable=broad-except
        print(f"Échec d'envoi de la notification pour {uid} : {e}")


# --- Lecture des emails et proposition de dossiers ---------------------
# Recherche de motif large plutôt qu'IA (décision du 2026-08-12 : gratuit,
# reste entièrement dans nos serveurs). Aucun vrai modèle d'email judiciaire
# trouvé publiquement (recherche du 2026-08-15) — on couvre large plutôt que
# de calibrer sur un exemple précis, et l'étape de confirmation rattrape le bruit.

_MOIS_FR = {
    "janvier": 1, "février": 2, "fevrier": 2, "mars": 3, "avril": 4, "mai": 5, "juin": 6,
    "juillet": 7, "août": 8, "aout": 8, "septembre": 9, "octobre": 10,
    "novembre": 11, "décembre": 12, "decembre": 12,
}
_RE_DATE_NUMERIQUE = re.compile(r"\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})\b")
_RE_DATE_LITTERALE = re.compile(
    r"\b(\d{1,2})(?:er)?\s+(" + "|".join(_MOIS_FR.keys()) + r")\s+(\d{4})\b",
    re.IGNORECASE,
)


def _extraire_dates(texte: str) -> list[date]:
    trouvees: list[date] = []
    for jour, mois, annee in _RE_DATE_NUMERIQUE.findall(texte):
        annee_i = int(annee) + 2000 if len(annee) == 2 else int(annee)
        try:
            trouvees.append(date(annee_i, int(mois), int(jour)))
        except ValueError:
            continue
    for jour, mois_txt, annee in _RE_DATE_LITTERALE.findall(texte):
        mois = _MOIS_FR.get(mois_txt.lower())
        if not mois:
            continue
        try:
            trouvees.append(date(int(annee), mois, int(jour)))
        except ValueError:
            continue

    # Écarte les dates farfelues (vieille référence de dossier, faux positif)
    # pour réduire le bruit — reste large, la confirmation humaine fait le reste.
    aujourdhui = date.today()
    trouvees = [d for d in trouvees if -30 < (d - aujourdhui).days < 400]

    vues: set[date] = set()
    resultat = []
    for d in trouvees:
        if d not in vues:
            vues.add(d)
            resultat.append(d)
    return resultat


# --- Extraction IA des emails (chemin alternatif à _extraire_dates) -----
# Activable par l'utilisateur (méthode "ia", jamais par défaut — voir
# automatisation_screen.dart, avertissement explicite avant activation :
# contrairement au Bilan, le contenu COMPLET de l'email part vers Groq, pas
# un texte anonymisé — c'est le prix à payer pour une meilleure fiabilité
# sur des emails mal formatés). Branché le 2026-08-22 (auparavant "en
# attente de financement").

_SYSTEME_EXTRACTION_EMAIL = (
    "Tu lis un email professionnel pour repérer une échéance à suivre "
    "(audience, rendez-vous, date limite...). Réponds UNIQUEMENT avec un "
    "objet JSON valide, sans aucun texte autour, avec exactement ces clés : "
    '{"dates": ["AAAA-MM-JJ", ...], "nomSuggere": "...", "resume": "..."}. '
    "\"dates\" : toutes les dates d'échéance/audience/rendez-vous "
    "explicitement mentionnées dans l'email — liste vide si aucune, ne "
    "jamais deviner ou approximer une date absente. \"nomSuggere\" : un "
    "titre très court (6 mots maximum) pour reconnaître cet email dans une "
    "liste, pas un résumé complet. \"resume\" : 1 à 2 phrases résumant ce "
    "que l'email annonce ou demande. Si l'email n'a rien d'exploitable, "
    "renvoie des listes/chaînes vides plutôt que d'inventer."
)


def _extraire_avec_ia(sujet: str, texte: str) -> dict:
    """Lit un email via Groq pour en extraire date(s), un titre court et un
    résumé — remplace _extraire_dates quand l'utilisateur a activé le
    chemin IA. En cas d'erreur (API indisponible, JSON invalide...), renvoie
    un résultat vide plutôt que de faire échouer tout le scan pour cet
    email : il retombe alors dans le chemin "sans date reconnue" déjà
    existant, traité comme un email à vérifier manuellement."""
    vide = {"dates": [], "nomSuggere": "", "resume": ""}
    try:
        reponse = requests.post(
            _URL_GROQ_CHAT,
            headers={
                "Authorization": f"Bearer {_groq_api_key.value}",
                "Content-Type": "application/json",
            },
            json={
                "model": _MODELE_GROQ,
                "messages": [
                    {"role": "system", "content": _SYSTEME_EXTRACTION_EMAIL},
                    {"role": "user", "content": f"Objet : {sujet[:200]}\n\n{texte[:6000]}"},
                ],
                "temperature": 0,
                "max_tokens": 300,
                "response_format": {"type": "json_object"},
            },
            timeout=20,
        )
        if reponse.status_code != 200:
            return vide
        contenu = reponse.json()["choices"][0]["message"]["content"]
        extrait = json.loads(contenu)
    except Exception:  # pylint: disable=broad-except
        return vide

    # Même garde-fou anti-farfelu que _extraire_dates (vieille référence,
    # faux positif) — la confirmation humaine fait le reste.
    aujourdhui = date.today()
    dates_valides: list[date] = []
    for texte_date in extrait.get("dates") or []:
        try:
            jour = date.fromisoformat(str(texte_date))
        except ValueError:
            continue
        if -30 < (jour - aujourdhui).days < 400:
            dates_valides.append(jour)

    return {
        "dates": dates_valides,
        "nomSuggere": str(extrait.get("nomSuggere") or "").strip()[:80],
        "resume": str(extrait.get("resume") or "").strip()[:400],
    }


def _decoder_base64url(data: str) -> str:
    try:
        return base64.urlsafe_b64decode(data + "=" * (-len(data) % 4)).decode("utf-8", errors="ignore")
    except Exception:  # pylint: disable=broad-except
        return ""


def _extraire_texte_partie(partie: dict) -> str:
    mime = partie.get("mimeType", "")
    corps = partie.get("body", {}).get("data")
    morceaux = [_extraire_texte_partie(p) for p in (partie.get("parts") or [])]
    morceaux = [m for m in morceaux if m]
    if morceaux:
        return "\n".join(morceaux)
    if corps and mime == "text/plain":
        return _decoder_base64url(corps)
    if corps and mime == "text/html":
        return re.sub(r"<[^>]+>", " ", _decoder_base64url(corps))
    return ""


def _texte_email(detail: dict) -> tuple[str, str]:
    sujet = ""
    for entete in detail.get("payload", {}).get("headers", []):
        if entete["name"] == "Subject":
            sujet = entete["value"]
    return sujet, _extraire_texte_partie(detail.get("payload", {}))


def _enregistrer_etat_sync(db, uid: str, source: str, succes: bool, erreur: str | None = None) -> None:
    """Trace la dernière exécution de chaque scan (Gmail/Tasks/Calendar) —
    sans ça, un échec silencieux (comme les scopes manquants du 2026-08-20)
    ne se voit nulle part côté utilisateur, juste une absence de résultat
    sans explication. Inspiré du "Dernière synchronisation" vu dans une app
    comparée (demande de Tobie le 2026-08-20)."""
    db.collection("utilisateurs").document(uid).collection("etatSync").document(source).set({
        "derniereExecution": firestore.SERVER_TIMESTAMP,
        "succes": succes,
        "erreur": erreur,
    })


@scheduler_fn.on_schedule(
    schedule=_HORAIRE,
    timezone=_FUSEAU,
    secrets=[_google_oauth_client_secret, _token_chiffrement_cle, _groq_api_key],
)
def scanner_emails(event: scheduler_fn.ScheduledEvent) -> None:
    db = firestore.client()

    for doc_utilisateur in db.collection("utilisateurs").stream():
        uid = doc_utilisateur.id
        data_utilisateur = doc_utilisateur.to_dict() or {}
        expediteurs = data_utilisateur.get("expediteursConfiance") or []
        if not expediteurs:
            continue
        methode = data_utilisateur.get("methodeExtraction", "motif")
        if methode not in ("motif", "ia"):
            continue  # valeur inconnue — par prudence, on ne traite pas.

        connexions = _connexions_actives(uid)
        if not connexions:
            continue

        # Boucle sur TOUS les comptes Google connectés (revu le 2026-08-21 :
        # aucun rôle prédéfini, on scanne chaque compte de la même façon) —
        # une erreur sur un compte n'empêche pas de scanner les autres.
        propositions_creees_total = 0
        emails_sans_date_total: list[dict] = []
        erreur_rencontree = None
        for connexion in connexions:
            jeton = _echanger_refresh_token(connexion["refreshTokenChiffre"])
            if jeton is None:
                continue
            try:
                propositions_creees, emails_sans_date = _scanner_boite(
                    db, uid, connexion["id"], expediteurs, jeton, methode
                )
                propositions_creees_total += propositions_creees
                emails_sans_date_total.extend(emails_sans_date)
            except Exception as e:  # pylint: disable=broad-except
                erreur_rencontree = f"{type(e).__name__}: {e}"
                print(f"Échec du scan emails pour {uid}/{connexion['id']} : {erreur_rencontree}")

        _enregistrer_etat_sync(db, uid, "gmail", succes=erreur_rencontree is None, erreur=erreur_rencontree)
        token = data_utilisateur.get("fcmToken")

        if propositions_creees_total > 0:
            digest = {
                "dossierId": None, "nomCodeDossier": None,
                "corps": f"{propositions_creees_total} nouvelle(s) proposition(s) de dossier à valider (emails détectés).",
                "parType": {}, "total": 0, "enRetard": 0,
            }
            if token:
                _envoyer(uid, token, digest, corps_public=digest["corps"])
            _enregistrer_historique(db, uid, digest)

        # La recherche de motif n'a rien trouvé d'exploitable dans ces
        # emails — on ne laisse pas ça filer sous silence, on prévient
        # pour un traitement manuel (demandé par Tobie le 2026-08-17).
        # Une notification PAR email (pas un compte groupé) : Tobie a
        # demandé de préciser qui a écrit et quand, pas juste un chiffre.
        for email_info in emails_sans_date_total:
            date_envoi = email_info["dateEnvoi"]
            date_fr = date_envoi.strftime("%d/%m/%Y") if date_envoi else "date inconnue"
            corps_manuel = (
                f"{email_info['expediteur']} t'a envoyé un email le {date_fr}"
                f" (« {email_info['sujet']} »), sans date reconnue automatiquement — "
                "ouvre ta boîte mail pour vérifier et ajoute la tâche toi-même si besoin."
            )
            digest_manuel = {
                "dossierId": None, "nomCodeDossier": None,
                "corps": corps_manuel,
                "parType": {}, "total": 0, "enRetard": 0,
            }
            if token:
                _envoyer(uid, token, digest_manuel)
            _enregistrer_historique(db, uid, digest_manuel)


def _scanner_boite(
    db, uid: str, connexion_id: str, expediteurs: list[str], jeton: str, methode: str
) -> tuple[int, list[dict]]:
    """Lit les emails récents des expéditeurs favoris d'UN compte Google
    connecté, crée une proposition par date trouvée. `methode` = "motif"
    (recherche de motif locale, par défaut) ou "ia" (lecture par Groq,
    activée explicitement par l'utilisateur). Renvoie (propositions créées,
    détails des emails sans aucune date trouvée — expéditeur/date d'envoi/
    sujet, pour un message de secours précis plutôt qu'un simple chiffre —
    décision du 2026-08-17)."""
    entetes = {"Authorization": f"Bearer {jeton}"}

    # Le suivi "déjà traité" est imbriqué sous la connexion (pas au niveau
    # utilisateur) depuis qu'il peut y avoir plusieurs comptes — évite toute
    # collision d'identifiant entre deux comptes différents.
    ref_traites = (
        db.collection("utilisateurs").document(uid)
        .collection("connexionsGoogle").document(connexion_id)
        .collection("emailsTraites")
    )
    deja_traites = {d.id for d in ref_traites.stream()}
    ref_propositions = db.collection("utilisateurs").document(uid).collection("propositions")

    propositions_creees = 0
    emails_sans_date: list[dict] = []
    for expediteur in expediteurs:
        recherche = requests.get(
            "https://gmail.googleapis.com/gmail/v1/users/me/messages",
            headers=entetes,
            params={"q": f"from:{expediteur} newer_than:14d", "maxResults": 20},
            timeout=15,
        ).json()

        for message in recherche.get("messages", []):
            message_id = message["id"]
            if message_id in deja_traites:
                continue

            detail = requests.get(
                f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}",
                headers=entetes,
                params={"format": "full"},
                timeout=10,
            ).json()
            sujet, texte = _texte_email(detail)
            date_envoi = _date_envoi_email(detail)

            if methode == "ia":
                extrait = _extraire_avec_ia(sujet, texte)
                dates_trouvees = extrait["dates"]
                nom_ia = extrait["nomSuggere"]
                resume_ia = extrait["resume"]
            else:
                dates_trouvees = _extraire_dates(f"{sujet}\n{texte}")
                nom_ia = ""
                resume_ia = ""

            if dates_trouvees:
                for jour in dates_trouvees:
                    ref_propositions.add({
                        "nomSuggere": nom_ia or f"À nommer — Audience du {jour.strftime('%d/%m/%Y')}",
                        "date": datetime(jour.year, jour.month, jour.day, tzinfo=timezone.utc),
                        "expediteur": expediteur,
                        "sujetEmail": sujet[:200],
                        "details": resume_ia,
                        "creeLe": firestore.SERVER_TIMESTAMP,
                        "statut": "enAttente",
                    })
                    propositions_creees += 1
            else:
                # Aucune date reconnue automatiquement : on crée quand même une
                # proposition, sans date pré-remplie (l'utilisateur la choisit
                # lui-même dans l'écran de création) — pour que ces emails ne
                # vivent pas QUE dans les notifications (demandé par Tobie le
                # 2026-08-17 : "c'est bien une proposition non ??").
                ref_propositions.add({
                    "nomSuggere": nom_ia or "À nommer",
                    "date": None,
                    "expediteur": expediteur,
                    "sujetEmail": sujet[:200] or "(sans objet)",
                    "details": resume_ia,
                    "creeLe": firestore.SERVER_TIMESTAMP,
                    "statut": "enAttente",
                })
                propositions_creees += 1
                emails_sans_date.append({
                    "expediteur": expediteur,
                    "sujet": sujet[:200] or "(sans objet)",
                    "dateEnvoi": date_envoi,
                })

            ref_traites.document(message_id).set({"traiteLe": firestore.SERVER_TIMESTAMP})

    return propositions_creees, emails_sans_date


def _date_envoi_email(detail: dict) -> datetime | None:
    """La vraie date d'envoi de l'email (champ interne Gmail, plus fiable
    que l'en-tête "Date" qui a trop de formats possibles à gérer)."""
    horodatage_ms = detail.get("internalDate")
    if not horodatage_ms:
        return None
    try:
        return datetime.fromtimestamp(int(horodatage_ms) / 1000, tz=timezone.utc)
    except (ValueError, TypeError):
        return None


def _enregistrer_historique(db, uid: str, digest: dict) -> None:
    db.collection("utilisateurs").document(uid).collection("notifications").add({
        "corps": digest["corps"],
        "dossierId": digest["dossierId"],
        "parType": digest["parType"],
        "total": digest["total"],
        "enRetard": digest["enRetard"],
        "envoyeLe": firestore.SERVER_TIMESTAMP,
    })


# --- Notifications instantanées de collaboration (Phase 2, 2026-08-31) -----
# Distinctes du digest quotidien ci-dessus : un événement précis (participant
# ajouté/retiré, rôle changé, proposition créée/résolue), pas un résumé de
# tâches en retard — `type` permet à l'écran Notifications de choisir une
# icône/un filtre adaptés (absent = 'digest' implicite, même convention de
# repli que le reste de ce fichier, pour que les entrées déjà existantes
# restent lisibles par un client mis à jour).

def _notifier_evenement(db, uid: str, *, type_evenement: str, corps: str, dossier_id: str | None) -> None:
    """Envoie une notification push (texte générique par défaut sur l'écran
    verrouillé, voir _envoyer/_CORPS_PUBLIC_PAR_DEFAUT — même principe que
    l'audit de sécurité du 2026-08-29 : jamais le nom d'un dossier ni qui a
    fait quoi hors de l'app) ET l'enregistre dans l'historique in-app
    (protégé par auth+PIN, où `corps` peut être détaillé sans risque).
    Best-effort sur le token manquant (utilisateur jamais connecté sur ce
    téléphone, ou token expiré) : l'historique reste écrit dans tous les cas,
    seul l'envoi push est sauté."""
    doc_utilisateur = db.collection("utilisateurs").document(uid).get()
    token = (doc_utilisateur.to_dict() or {}).get("fcmToken")
    if token:
        _envoyer(uid, token, {"dossierId": dossier_id})
    db.collection("utilisateurs").document(uid).collection("notifications").add({
        "corps": corps,
        "dossierId": dossier_id,
        "type": type_evenement,
        # total/enRetard/parType n'ont pas de sens pour un événement de
        # collaboration (contrairement au digest) — gardés à zéro/vide plutôt
        # qu'absents pour qu'un client pas encore mis à jour (qui lirait ces
        # champs sans repli) ne plante pas dessus.
        "total": 0,
        "enRetard": 0,
        "parType": {},
        "envoyeLe": firestore.SERVER_TIMESTAMP,
    })


def _notifier_evenements_gestion_participant(db, action: str, demandeur_uid: str, dossier_id: str, resultat: dict) -> None:
    """Événements (a)-(d) du plan Phase 2 — appelé après que la transaction
    de gerer_participant_dossier a réussi. Deux publics distincts, jamais
    confondus (retrouvé en corrigeant une première version de ce plan qui
    notifiait uniquement le créateur pour les 4 événements — ne correspondait
    à AUCUNE des remarques réelles de Tobie) :
    - la personne directement touchée (ajoutée/retirée/changée de rôle) —
      remarques "aucune notification à celui qui a été ajouté" et "un
      contributeur retiré n'est pas notifié" ;
    - le créateur EN PLUS, quand ce n'est PAS lui qui a agi (un administrateur
      a géré un participant en son nom) — remarque "quand un admin ajoute un
      contributeur, le créateur doit être notifié", étendue par cohérence à
      retirer/changerRole (même logique de transparence sur ce qu'un
      administrateur fait en son nom, pas seulement le cas "ajouter").
    Jamais de auto-notification (on ne s'notifie pas soi-même de sa propre
    action, ex: auto-retrait)."""
    nom = resultat["_nomCodeDossier"]
    cible_uid = resultat["_cibleUid"]
    cible_email = resultat["_cibleEmail"] or "quelqu'un"
    demandeur_email = resultat["_demandeurEmail"] or "Un administrateur"
    nouveau_role = resultat["_nouveauRole"]
    demandeur_est_createur = resultat["_roleDemandeur"] == "createur"

    if action == "ajouter" and cible_uid and cible_uid != demandeur_uid:
        _notifier_evenement(
            db, cible_uid,
            type_evenement="participantAjoute",
            corps=f"Tu as été ajouté(e) au dossier {nom} en tant que {nouveau_role}.",
            dossier_id=dossier_id,
        )
    elif action == "retirer" and cible_uid and cible_uid != demandeur_uid:
        _notifier_evenement(
            db, cible_uid,
            type_evenement="participantRetire",
            corps=f"Tu as été retiré(e) du dossier {nom}.",
            dossier_id=dossier_id,
        )
    elif action == "changerRole" and cible_uid and cible_uid != demandeur_uid:
        _notifier_evenement(
            db, cible_uid,
            type_evenement="roleModifie",
            corps=f"Ton rôle sur le dossier {nom} est maintenant {nouveau_role}.",
            dossier_id=dossier_id,
        )

    if action in ("ajouter", "retirer", "changerRole") and not demandeur_est_createur and cible_uid:
        # Le créateur n'est jamais la cible de ces trois actions (protégé
        # plus haut dans gerer_participant_dossier), donc pas de risque de le
        # notifier deux fois de la même action ; `demandeur_est_createur`
        # ci-dessus exclut déjà le cas où c'est lui-même qui agit.
        proprietaire_uid = resultat["_proprietaireUid"]
        if not proprietaire_uid:
            return
        verbe = {"ajouter": "a ajouté", "retirer": "a retiré", "changerRole": "a changé le rôle de"}[action]
        complement = f" ({nouveau_role})" if action == "changerRole" else ""
        _notifier_evenement(
            db, proprietaire_uid,
            type_evenement="ajoutParAdministrateur",
            corps=f"{demandeur_email} {verbe} {cible_email}{complement} dans le dossier {nom}.",
            dossier_id=dossier_id,
        )


# --- Notifications de proposition (événements e/f du plan Phase 2) --------
# Première fonction déclenchée par Firestore de ce projet (jusqu'ici,
# seulement https_fn/scheduler_fn) : contrairement à gerer_participant_dossier
# (qui sait exactement quand une proposition est créée/résolue puisque c'est
# elle qui l'écrit), une proposition côté tâches/journal peut être posée,
# révisée ou résolue par n'importe quel participant en écriture directe (voir
# firestore.rules, Chemin B) — il n'y a pas de fonction serveur unique par
# laquelle ça passe toujours, donc pas d'endroit unique où "brancher" l'envoi
# à la main. Un déclencheur Firestore observe le résultat plutôt que
# d'essayer d'intercepter chaque chemin d'écriture possible.


def _proposition_approuvee(avant_doc: dict, apres_doc: dict | None) -> bool:
    """Une proposition passe de "en attente" à "résolue" soit parce que le
    créateur/gestionnaire a appliqué le changement proposé (approuvé), soit
    parce qu'il a juste remis propositionEnAttente à null sans rien changer
    d'autre (rejeté) — comparer le reste du document avant/après (tout sauf
    propositionEnAttente lui-même) distingue les deux sans avoir besoin d'un
    champ "statut" séparé. Document supprimé (apres_doc is None) : traité
    comme approuvé dans tous les cas (voir plan Phase 2) — la proposition a
    disparu avec son document, pas de sens à dire "rejeté"."""
    if apres_doc is None:
        return True
    avant_sans_proposition = {k: v for k, v in avant_doc.items() if k != "propositionEnAttente"}
    apres_sans_proposition = {k: v for k, v in apres_doc.items() if k != "propositionEnAttente"}
    return avant_sans_proposition != apres_sans_proposition


def _proprietaire_dossier(db, dossier_id: str | None) -> str | None:
    if not dossier_id:
        return None
    doc = db.collection("dossiers").document(dossier_id).get()
    return (doc.to_dict() or {}).get("uid") if doc.exists else None


def _traiter_changement_proposition(event: firestore_fn.Event) -> None:
    """Partagé entre taches/{tacheId} et journalDossier/{entreeId} — les deux
    portent propositionEnAttente/dossierId/nomCodeDossier de la même façon
    (voir plan Phase 2). Sortie rapide si propositionEnAttente n'a PAS changé
    (trouvé en concevant ce déclencheur : il se déclenche à CHAQUE écriture
    sur ces collections, y compris la création normale d'une tâche et les
    cascades de _synchroniser_participants_dossier — sans cette garde, ce
    serait un coût réel à chaque fois, pas juste une optimisation accessoire)."""
    avant = event.data.before.to_dict() if event.data.before is not None else None
    apres = event.data.after.to_dict() if event.data.after is not None else None

    proposition_avant = (avant or {}).get("propositionEnAttente")
    proposition_apres = (apres or {}).get("propositionEnAttente")
    if proposition_avant == proposition_apres:
        return

    reference = apres or avant or {}
    dossier_id = reference.get("dossierId")
    nom = reference.get("nomCodeDossier") or "Dossier"
    db = firestore.client()

    if proposition_avant is None and proposition_apres is not None:
        proprietaire_uid = _proprietaire_dossier(db, dossier_id)
        if proprietaire_uid:
            _notifier_evenement(
                db, proprietaire_uid,
                type_evenement="propositionCreee",
                corps=f"Une proposition attend ta validation dans le dossier {nom}.",
                dossier_id=dossier_id,
            )
    elif proposition_avant is not None and proposition_apres is None:
        propose_par_uid = proposition_avant.get("proposePar")
        if not propose_par_uid:
            return
        approuvee = _proposition_approuvee(avant or {}, apres)
        corps = (
            f"Ta proposition dans le dossier {nom} a été approuvée."
            if approuvee else
            f"Ta proposition dans le dossier {nom} a été rejetée."
        )
        _notifier_evenement(
            db, propose_par_uid,
            type_evenement="propositionResolue",
            corps=corps,
            dossier_id=dossier_id,
        )
    # Sinon (proposition révisée : non-null -> non-null, ex. le proposeur
    # modifie sa propre proposition en attente) : rien à notifier, ni
    # création ni résolution — un seul et même événement encore en attente.


@firestore_fn.on_document_written(document="taches/{tacheId}")
def notifier_proposition_tache(event: firestore_fn.Event) -> None:
    try:
        _traiter_changement_proposition(event)
    except Exception as e:  # pylint: disable=broad-except
        print(f"Échec de notification de proposition (taches/{event.params.get('tacheId')}) : {type(e).__name__}: {e}")


@firestore_fn.on_document_written(document="journalDossier/{entreeId}")
def notifier_proposition_journal(event: firestore_fn.Event) -> None:
    try:
        _traiter_changement_proposition(event)
    except Exception as e:  # pylint: disable=broad-except
        print(f"Échec de notification de proposition (journalDossier/{event.params.get('entreeId')}) : {type(e).__name__}: {e}")


# --- Publication de version (bannière de mise à jour dans l'app) -------

_URL_APK_OFFICIELLE = "https://vigie.pentalightcode.com/telecharger/"


@https_fn.on_request(secrets=[_admin_publication_secret])
def publier_version_admin(req: https_fn.Request) -> https_fn.Response:
    """Écrit /config/version — appelée uniquement par
    scripts/publier_version.py après chaque nouvelle build. Protégée par
    secret plutôt qu'ouverte à tous : sans ça, n'importe qui pourrait
    pointer la bannière de mise à jour vers un fichier malveillant."""
    if req.method != "POST":
        return https_fn.Response("Méthode non autorisée.", status=405)

    corps = req.get_json(silent=True) or {}
    secret_recu = corps.get("secret", "").strip()
    if not hmac.compare_digest(secret_recu, _admin_publication_secret.value.strip()):
        return https_fn.Response("Non autorisé.", status=403)

    try:
        version = str(corps["version"])
        build = int(corps["build"])
        url_apk = str(corps["urlApk"])
    except (KeyError, TypeError, ValueError):
        return https_fn.Response("Champs invalides (version, build, urlApk requis).", status=400)

    # Garde-fou : même avec le secret, on n'autorise jamais de pointer vers
    # un domaine autre que le nôtre.
    if not url_apk.startswith(_URL_APK_OFFICIELLE):
        return https_fn.Response("urlApk doit être sur vigie.pentalightcode.com/telecharger/.", status=400)

    db = firestore.client()
    db.collection("config").document("version").set({
        "version": version,
        "build": build,
        "urlApk": url_apk,
        "publieLe": firestore.SERVER_TIMESTAMP,
    })

    # Alerte push envoyée à chaque publication — la bannière dans l'app seule
    # ne suffisait pas (le bouton "Télécharger" échoue silencieusement sur
    # certains téléphones, ex: Xiaomi/MIUI, cause non trouvée malgré
    # plusieurs tentatives) : décision du 2026-08-17 avec Tobie de repasser
    # par une vraie notification qui renvoie vers le site plutôt que
    # d'essayer d'ouvrir un navigateur depuis l'app elle-même.
    notifier = corps.get("notifier", True)
    nb_notifies = 0
    if notifier:
        for doc_utilisateur in db.collection("utilisateurs").stream():
            token = (doc_utilisateur.to_dict() or {}).get("fcmToken")
            if not token:
                continue
            digest = {
                "dossierId": None, "nomCodeDossier": None,
                "corps": (
                    f"Nouvelle version de Vigie disponible ({version}) — "
                    "va sur vigie.pentalightcode.com pour la télécharger."
                ),
                "parType": {}, "total": 0, "enRetard": 0,
            }
            _envoyer(doc_utilisateur.id, token, digest, lien="https://vigie.pentalightcode.com", corps_public=digest["corps"])
            _enregistrer_historique(db, doc_utilisateur.id, digest)
            nb_notifies += 1

    return https_fn.Response(
        f"Version {version} (build {build}) publiée, {nb_notifies} utilisateur(s) notifié(s).",
        status=200,
    )


# --- Import Google Tasks (demandé par Tobie le 2026-08-18) -------------
# Contrairement aux emails, une tâche Google est déjà structurée (titre +
# date d'échéance) : aucun besoin de motif/regex ni d'IA pour en extraire
# une date. Réutilise le même jeton OAuth que Gmail (même connexion, deux
# autorisations demandées ensemble côté app — voir gmail_service.dart).

_URL_TASKS_LISTES = "https://tasks.googleapis.com/tasks/v1/users/@me/lists"
_URL_TASKS_TACHES = "https://tasks.googleapis.com/tasks/v1/lists/{}/tasks"


@scheduler_fn.on_schedule(schedule=_HORAIRE, timezone=_FUSEAU, secrets=[_google_oauth_client_secret, _token_chiffrement_cle])
def scanner_taches_google(event: scheduler_fn.ScheduledEvent) -> None:
    db = firestore.client()

    for doc_utilisateur in db.collection("utilisateurs").stream():
        uid = doc_utilisateur.id
        data_utilisateur = doc_utilisateur.to_dict() or {}
        connexions = _connexions_actives(uid)
        if not connexions:
            continue

        propositions_creees_total = 0
        erreur_rencontree = None
        for connexion in connexions:
            jeton = _echanger_refresh_token(connexion["refreshTokenChiffre"])
            if jeton is None:
                continue
            try:
                propositions_creees_total += _scanner_taches(db, uid, connexion["id"], jeton)
            except Exception as e:  # pylint: disable=broad-except
                erreur_rencontree = f"{type(e).__name__}: {e}"
                print(f"Échec du scan tâches pour {uid}/{connexion['id']} : {erreur_rencontree}")

        _enregistrer_etat_sync(db, uid, "tasks", succes=erreur_rencontree is None, erreur=erreur_rencontree)
        if propositions_creees_total > 0:
            token = data_utilisateur.get("fcmToken")
            digest = {
                "dossierId": None, "nomCodeDossier": None,
                "corps": f"{propositions_creees_total} tâche(s) Google Tasks importée(s), à valider.",
                "parType": {}, "total": 0, "enRetard": 0,
            }
            if token:
                _envoyer(uid, token, digest, corps_public=digest["corps"])
            _enregistrer_historique(db, uid, digest)


def _scanner_taches(db, uid: str, connexion_id: str, jeton: str) -> int:
    """Importe les tâches Google Tasks non terminées AVEC une échéance d'UN
    compte Google connecté comme Propositions (les tâches sans date ne sont
    pas importées pour l'instant — beaucoup de gens utilisent Tasks comme
    simple liste sans date, importer ça noierait les vraies échéances)."""
    entetes = {"Authorization": f"Bearer {jeton}"}

    ref_traitees = (
        db.collection("utilisateurs").document(uid)
        .collection("connexionsGoogle").document(connexion_id)
        .collection("tachesGoogleTraitees")
    )
    deja_traitees = {d.id for d in ref_traitees.stream()}
    ref_propositions = db.collection("utilisateurs").document(uid).collection("propositions")

    listes = requests.get(_URL_TASKS_LISTES, headers=entetes, timeout=15).json().get("items", [])

    propositions_creees = 0
    for liste in listes:
        taches = requests.get(
            _URL_TASKS_TACHES.format(liste["id"]),
            headers=entetes,
            params={"showCompleted": "false", "showHidden": "false", "maxResults": 100},
            timeout=15,
        ).json().get("items", [])

        for tache in taches:
            tache_id = tache["id"]
            if tache_id in deja_traitees:
                continue

            echeance = tache.get("due")  # ex: "2026-08-20T00:00:00.000Z"
            if echeance:
                jour = datetime.fromisoformat(echeance.replace("Z", "+00:00")).date()
                ref_propositions.add({
                    "nomSuggere": "À nommer",
                    "date": datetime(jour.year, jour.month, jour.day, tzinfo=timezone.utc),
                    "expediteur": "Google Tasks",
                    "sujetEmail": (tache.get("title") or "(sans titre)")[:200],
                    # Détails d'origine (demandé par Tobie le 2026-08-20 :
                    # le père voyait le titre mais perdait les notes de la
                    # tâche Google une fois importée).
                    "details": (tache.get("notes") or "")[:2000],
                    "creeLe": firestore.SERVER_TIMESTAMP,
                    "statut": "enAttente",
                })
                propositions_creees += 1

            ref_traitees.document(tache_id).set({"traiteeLe": firestore.SERVER_TIMESTAMP})

    return propositions_creees


# --- Import Google Calendar (demandé par Tobie le 2026-08-18, juste après
# Tasks : "on ne peut pas parler de Google Tasks sans Google Calendar") -----
# Même principe que Tasks : un événement de calendrier est déjà structuré
# (titre + date), aucune extraction à faire. Réutilise le même jeton OAuth
# (même connexion, trois autorisations demandées ensemble côté app).

_URL_CALENDAR_EVENEMENTS = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
_FENETRE_CALENDRIER = timedelta(days=30)


@scheduler_fn.on_schedule(schedule=_HORAIRE, timezone=_FUSEAU, secrets=[_google_oauth_client_secret, _token_chiffrement_cle])
def scanner_calendrier_google(event: scheduler_fn.ScheduledEvent) -> None:
    db = firestore.client()

    for doc_utilisateur in db.collection("utilisateurs").stream():
        uid = doc_utilisateur.id
        data_utilisateur = doc_utilisateur.to_dict() or {}
        connexions = _connexions_actives(uid)
        if not connexions:
            continue

        propositions_creees_total = 0
        erreur_rencontree = None
        for connexion in connexions:
            jeton = _echanger_refresh_token(connexion["refreshTokenChiffre"])
            if jeton is None:
                continue
            try:
                propositions_creees_total += _scanner_calendrier(db, uid, connexion["id"], jeton)
            except Exception as e:  # pylint: disable=broad-except
                erreur_rencontree = f"{type(e).__name__}: {e}"
                print(f"Échec du scan calendrier pour {uid}/{connexion['id']} : {erreur_rencontree}")

        _enregistrer_etat_sync(db, uid, "calendar", succes=erreur_rencontree is None, erreur=erreur_rencontree)
        if propositions_creees_total > 0:
            token = data_utilisateur.get("fcmToken")
            digest = {
                "dossierId": None, "nomCodeDossier": None,
                "corps": f"{propositions_creees_total} événement(s) de calendrier importé(s), à valider.",
                "parType": {}, "total": 0, "enRetard": 0,
            }
            if token:
                _envoyer(uid, token, digest, corps_public=digest["corps"])
            _enregistrer_historique(db, uid, digest)


def _scanner_calendrier(db, uid: str, connexion_id: str, jeton: str) -> int:
    """Importe les événements des 30 prochains jours du calendrier principal
    d'UN compte Google connecté comme Propositions — rien n'est filtré par
    pertinence (un anniversaire compte comme un rendez-vous pro)
    volontairement : c'est à l'utilisateur d'ignorer ce qui ne correspond
    pas à un dossier, comme pour tout le reste (aucune décision automatique)."""
    entetes = {"Authorization": f"Bearer {jeton}"}

    ref_traites = (
        db.collection("utilisateurs").document(uid)
        .collection("connexionsGoogle").document(connexion_id)
        .collection("evenementsGoogleTraites")
    )
    deja_traites = {d.id for d in ref_traites.stream()}
    ref_propositions = db.collection("utilisateurs").document(uid).collection("propositions")

    maintenant = datetime.now(timezone.utc)
    reponse = requests.get(
        _URL_CALENDAR_EVENEMENTS,
        headers=entetes,
        params={
            "timeMin": maintenant.isoformat(),
            "timeMax": (maintenant + _FENETRE_CALENDRIER).isoformat(),
            "singleEvents": "true",
            "orderBy": "startTime",
            "maxResults": 100,
        },
        timeout=15,
    ).json()

    propositions_creees = 0
    for evenement in reponse.get("items", []):
        # Un événement récurrent (ex: "PENTALIGHTCODE — Session soir" chaque
        # mercredi) génère une instance par occurrence, chacune avec son
        # propre id — sans ça, on reproposerait le même dossier chaque
        # semaine indéfiniment. "recurringEventId" identifie la série entière
        # (stable pour toutes ses occurrences) : on ne traite que la
        # première rencontrée, jamais les suivantes (trouvé en creusant les
        # vraies données de Tobie le 2026-08-20).
        cle_dedup = evenement.get("recurringEventId") or evenement["id"]
        if cle_dedup in deja_traites or evenement.get("status") == "cancelled":
            continue

        # "date" pour un événement journée entière, "dateTime" sinon.
        debut = evenement.get("start", {})
        date_str = debut.get("date") or (debut.get("dateTime") or "")[:10]
        if not date_str:
            ref_traites.document(cle_dedup).set({"traiteLe": firestore.SERVER_TIMESTAMP})
            continue

        jour = date.fromisoformat(date_str)
        ref_propositions.add({
            "nomSuggere": "À nommer",
            "date": datetime(jour.year, jour.month, jour.day, tzinfo=timezone.utc),
            "expediteur": "Google Calendar",
            "sujetEmail": (evenement.get("summary") or "(sans titre)")[:200],
            # Détails d'origine (demandé par Tobie le 2026-08-20 : le père
            # voyait le titre mais perdait la description de l'événement
            # Google une fois importée).
            "details": (evenement.get("description") or "")[:2000],
            "creeLe": firestore.SERVER_TIMESTAMP,
            "statut": "enAttente",
        })
        propositions_creees += 1
        ref_traites.document(cle_dedup).set({"traiteLe": firestore.SERVER_TIMESTAMP})

    return propositions_creees


@https_fn.on_call(secrets=[_google_oauth_client_secret, _token_chiffrement_cle])
def lister_evenements_calendrier(req: https_fn.CallableRequest) -> dict:
    """Lit les événements du calendrier principal de TOUS les comptes Google
    connectés sur une période donnée, fusionnés en une seule liste — pour
    l'écran Agenda (vue en direct, distincte de scanner_calendrier_google
    qui importe en Propositions). Demandé par Tobie le 2026-08-19 : le père
    veut VOIR son agenda Google dans l'app, pas seulement recevoir des
    propositions de dossier ; étendu le 2026-08-21 à plusieurs comptes."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")

    connexions = _connexions_actives(req.auth.uid)
    if not connexions:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.FAILED_PRECONDITION, "Aucun compte Google connecté.")

    donnees = req.data or {}
    try:
        debut = datetime.fromisoformat(donnees["debut"]).replace(tzinfo=timezone.utc)
        fin = datetime.fromisoformat(donnees["fin"]).replace(tzinfo=timezone.utc)
    except (KeyError, ValueError) as e:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "debut/fin invalides.") from e

    evenements = []
    for connexion in connexions:
        jeton = _echanger_refresh_token(connexion["refreshTokenChiffre"])
        if jeton is None:
            continue
        entetes = {"Authorization": f"Bearer {jeton}"}
        reponse = requests.get(
            _URL_CALENDAR_EVENEMENTS,
            headers=entetes,
            params={
                "timeMin": debut.isoformat(),
                "timeMax": fin.isoformat(),
                "singleEvents": "true",
                "orderBy": "startTime",
                "maxResults": 250,
            },
            timeout=15,
        ).json()

        for evenement in reponse.get("items", []):
            if evenement.get("status") == "cancelled":
                continue
            debut_ev = evenement.get("start", {})
            date_str = debut_ev.get("date") or (debut_ev.get("dateTime") or "")[:10]
            if not date_str:
                continue
            evenements.append({
                # Préfixé par la connexion : deux comptes différents peuvent
                # en théorie réutiliser un même identifiant d'événement.
                "id": f"{connexion['id']}_{evenement['id']}",
                "titre": evenement.get("summary") or "(sans titre)",
                "date": date_str,
                "journeeEntiere": "date" in debut_ev,
                "description": evenement.get("description") or "",
            })

    return {"evenements": evenements}


# --- Résumé + recommandations IA du Bilan (Groq) ------------------------
# Fonctionnalité activable par l'utilisateur (jamais par défaut — même
# principe que le chemin IA pour l'extraction Gmail, décision du 2026-08-15) :
# le texte envoyé est exactement celui déjà utilisé pour le partage anonymisé
# du Bilan (dossiers désignés par des noms de code choisis par l'utilisateur,
# jamais de vraies informations) — aucune donnée de plus ne sort vers Groq
# que ce que l'utilisateur partage déjà volontairement ailleurs dans l'app.

_SYSTEME_RESUME_BILAN = (
    "Tu résumes un bilan d'activité personnel. L'utilisateur suit des dossiers "
    "désignés par des noms de code (jamais de vraies informations) — ne cherche "
    "jamais à deviner de quoi il s'agit réellement, ne les commente pas comme "
    "s'ils étaient de vraies affaires. Réponds en français, texte brut (pas de "
    "markdown, pas d'émoji). D'abord un résumé factuel en 2 à 4 phrases de la "
    "période. Ensuite, sur une nouvelle ligne commençant par \"Recommandations :\", "
    "2 à 3 recommandations concrètes et actionnables basées uniquement sur les "
    "chiffres fournis (ex : dossiers en retard à prioriser, régularité à féliciter "
    "ou à améliorer). Reste bref, pas de généralités creuses."
)


@https_fn.on_call(secrets=[_groq_api_key], timeout_sec=30)
def generer_resume_bilan(req: https_fn.CallableRequest) -> dict:
    """Envoie le texte du Bilan (même contenu anonymisé que le partage) à
    Groq et renvoie un résumé + des recommandations. Appelée à la demande
    (bouton), jamais automatiquement — activable/désactivable par
    l'utilisateur (voir bilanIaActif côté app)."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")

    texte_bilan = ((req.data or {}).get("texteBilan") or "").strip()[:8000]
    if not texte_bilan:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Bilan vide.")

    reponse = requests.post(
        _URL_GROQ_CHAT,
        headers={
            "Authorization": f"Bearer {_groq_api_key.value}",
            "Content-Type": "application/json",
        },
        json={
            "model": _MODELE_GROQ,
            "messages": [
                {"role": "system", "content": _SYSTEME_RESUME_BILAN},
                {"role": "user", "content": texte_bilan},
            ],
            "temperature": 0.3,
            "max_tokens": 400,
        },
        timeout=20,
    )
    if reponse.status_code != 200:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.UNAVAILABLE,
            f"Groq indisponible ({reponse.status_code}).",
        )

    resultat = reponse.json()
    resume = resultat["choices"][0]["message"]["content"].strip()
    return {"resume": resume}


# --- Suppression définitive de compte -----------------------------------
# Trouvé lors de l'audit du 2026-08-29 : la suppression de compte se faisait
# entièrement côté téléphone (utilisateur_service.dart), et ne supprimait
# QUE dossiers/taches/naturesDossier/le document racine — jamais journalDossier
# (notes de dossier), notifications (historique), propositions,
# connexionsGoogle (jeton Google chiffré, ni supprimé ni révoqué auprès de
# Google !), etatSync, etatsNotifies. Un compte "définitivement supprimé"
# laissait donc des données sensibles orphelines pour toujours, et une
# autorisation Google active à vie. Bougé côté serveur : c'est le seul
# endroit qui a la clé pour révoquer les jetons Google, et Admin SDK peut
# découvrir TOUTES les sous-collections automatiquement (.collections()),
# donc reste correct même si de nouvelles sous-collections sont ajoutées
# plus tard sans qu'on pense à mettre cette fonction à jour.

def _supprimer_sous_collections(doc_ref) -> None:
    """Parcourt récursivement toutes les sous-collections d'un document et
    supprime chaque document trouvé, par lots de 400 (limite du batch
    Firestore : 500) plutôt qu'un par un — les collections de suivi interne
    (emails/tâches/événements "déjà traités") peuvent accumuler beaucoup de
    documents sur un compte utilisé depuis des mois."""
    a_supprimer: list = []

    def _explorer(ref) -> None:
        for sous_collection in ref.collections():
            for sous_doc in sous_collection.stream():
                if sous_collection.id == "connexionsGoogle":
                    chiffre = (sous_doc.to_dict() or {}).get("refreshTokenChiffre")
                    if chiffre:
                        _revoquer_connexion_google(chiffre)
                _explorer(sous_doc.reference)
                a_supprimer.append(sous_doc.reference)

    _explorer(doc_ref)

    db = firestore.client()
    for i in range(0, len(a_supprimer), 400):
        batch = db.batch()
        for ref in a_supprimer[i:i + 400]:
            batch.delete(ref)
        batch.commit()


def _supprimer_par_lots(query, taille_lot: int = 400) -> None:
    db = firestore.client()
    docs = list(query.stream())
    for i in range(0, len(docs), taille_lot):
        batch = db.batch()
        for doc in docs[i:i + taille_lot]:
            batch.delete(doc.reference)
        batch.commit()


def _synchroniser_participants_dossier(db, dossier_id: str) -> None:
    """Recopie participantsUids sur les tâches/entrées de journal déjà
    existantes d'un dossier (refonte collaboration du 2026-08-29) — les
    documents créés APRÈS ce changement reçoivent déjà la bonne liste depuis
    le téléphone (voir FirestoreService.ajouterTacheADossier /
    ajouterEntreeJournal), seuls les anciens doivent être rattrapés ici.

    Relit la liste ACTUELLE du dossier au lieu de recevoir une valeur figée
    en paramètre (trouvé en Red Team le 2026-08-30, via /code-review) : deux
    appels concurrents (deux administrateurs qui gèrent des participants
    presque en même temps) synchronisaient chacun avec la liste qu'ILS
    venaient d'écrire — si leurs synchronisations s'exécutaient dans le désordre
    (aucune garantie d'ordre entre deux appels serveur indépendants), la plus
    lente pouvait écraser le résultat de la plus récente. Relire la vraie
    liste au moment de la synchronisation, plutôt que de faire confiance à
    une valeur capturée plus tôt, fait converger vers le bon état quel que
    soit l'ordre d'exécution.

    Best-effort, jamais bloquant (trouvé en re-vérifiant ce correctif, via
    /code-review, le 2026-08-31) : cette synchronisation se produit APRÈS
    que le retrait/ajout du participant a déjà été validé par la
    transaction sur le dossier lui-même — une vraie atomicité serait
    impossible ici (un dossier peut avoir bien plus de documents que la
    limite d'une transaction Firestore). Si elle échoue partiellement
    (panne, délai dépassé sur un très gros dossier), l'échec est au moins
    journalisé au lieu de rester totalement silencieux, mais ne fait pas
    échouer l'appel entier : l'action principale (ajout/retrait) a déjà
    réussi, la resynchronisation se rattrapera à la prochaine gestion de
    participants sur ce dossier.

    La relecture initiale du dossier (ligne suivante) est protégée par le
    MÊME filet que les deux collections ci-dessous, pas seulement elles
    (trouvé en re-vérifiant ce correctif une deuxième fois, via /code-review,
    le 2026-08-31) : une erreur transitoire pile à cette lecture aurait
    propagé une exception non gérée jusqu'à l'appelant (gerer_participant_dossier),
    faisant croire à un échec total de l'action alors que l'ajout/retrait
    avait déjà réussi juste avant."""
    try:
        dossier_doc = db.collection("dossiers").document(dossier_id).get()
        participants_uids = (dossier_doc.to_dict() or {}).get("participantsUids") or []
    except Exception as e:  # pylint: disable=broad-except
        print(f"Échec de relecture du dossier {dossier_id} pour synchronisation : {type(e).__name__}: {e}")
        return
    for collection in ("taches", "journalDossier"):
        try:
            docs = list(db.collection(collection).where("dossierId", "==", dossier_id).stream())
            for i in range(0, len(docs), 400):
                batch = db.batch()
                for doc in docs[i:i + 400]:
                    batch.update(doc.reference, {"participantsUids": participants_uids})
                batch.commit()
        except Exception as e:  # pylint: disable=broad-except
            print(f"Échec de synchronisation ({collection}) pour le dossier {dossier_id} : {type(e).__name__}: {e}")


@https_fn.on_call(secrets=[_token_chiffrement_cle], timeout_sec=120)
def supprimer_compte_definitivement(req: https_fn.CallableRequest) -> dict:
    """Supprime VRAIMENT tout : révoque chaque connexion Google auprès de
    Google, efface toutes les données Firestore (collections de premier
    niveau filtrées par uid + toutes les sous-collections, découvertes
    automatiquement), puis supprime le compte de connexion (Admin SDK).
    Irréversible — protégé par la triple confirmation déjà en place côté
    écran Profil, qui n'appelle plus que cette fonction désormais."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")
    uid = req.auth.uid
    db = firestore.client()

    # Tâches/entrées de journal des dossiers que ce compte POSSÈDE, par
    # dossierId (trouvé en Red Team le 2026-08-30, via /code-review) : `uid`
    # sur journalDossier vaut l'AUTEUR réel, pas le propriétaire du dossier —
    # une entrée écrite par un AUTRE participant (Bob) dans le dossier de ce
    # compte (Alice) a `uid: Bob`, jamais retrouvée par un filtre `uid==`.
    ids_dossiers_possedes = [d.id for d in db.collection("dossiers").where("uid", "==", uid).stream()]
    for dossier_id in ids_dossiers_possedes:
        _supprimer_par_lots(db.collection("taches").where("dossierId", "==", dossier_id))
        _supprimer_par_lots(db.collection("journalDossier").where("dossierId", "==", dossier_id))
    _supprimer_par_lots(db.collection("dossiers").where("uid", "==", uid))
    # Filtre `uid==` gardé EN PLUS du filtre par dossierId ci-dessus (retrouvé
    # en re-vérifiant ce correctif, via /code-review) : le filtre par
    # dossierId ne retrouve que le contenu des dossiers ACTUELLEMENT possédés
    # — un document déjà orphelin (dossier supprimé par un autre moyen avant
    # ce correctif, ex. avant que journalDossier soit inclus dans
    # FirestoreService.supprimerDossier) ne serait jamais retrouvé sans ce
    # filtre complémentaire sur les propres documents de ce compte.
    _supprimer_par_lots(db.collection("taches").where("uid", "==", uid))
    _supprimer_par_lots(db.collection("journalDossier").where("uid", "==", uid))
    # Tâches AUTEURÉES (pas possédées) par ce compte dans le dossier de
    # quelqu'un d'autre (trouvé en re-vérifiant ce correctif, via
    # /code-review, le 2026-08-31) : `taches.uid` vaut le PROPRIÉTAIRE du
    # dossier, jamais l'auteur réel d'un contributeur — le même écart déjà
    # corrigé pour journalDossier ci-dessus, manqué pour taches puisque
    # `auteurUid` n'y a jamais été interrogé. Sans ce filtre, une tâche
    # ajoutée par ce compte au dossier d'un autre restait pour toujours,
    # attribuée à un compte qui n'existe plus.
    _supprimer_par_lots(db.collection("taches").where("auteurUid", "==", uid))

    # Retire ce compte des dossiers PARTAGÉS appartenant à d'autres personnes
    # (trouvé le 2026-08-29 pendant l'exploration collaboration, Angle 66 :
    # sans ça, un compte supprimé restait "participant fantôme" — toujours
    # listé dans participantsUids/roles — dans les dossiers des autres).
    for doc in db.collection("dossiers").where("participantsUids", "array_contains", uid).stream():
        data = doc.to_dict() or {}
        if data.get("uid") == uid:
            continue  # dossier dont ce compte était propriétaire, déjà supprimé ci-dessus
        nouveaux_participants = [p for p in (data.get("participantsUids") or []) if p != uid]
        nouveaux_roles = {k: v for k, v in (data.get("roles") or {}).items() if k != uid}
        # participantsEmails aussi (trouvé en Red Team le 2026-08-30, via
        # /code-review) : oublié initialement, laissait l'email du compte
        # supprimé visible indéfiniment dans le dossier des autres alors même
        # que le compte était censé être "vraiment" supprimé.
        nouveaux_emails = {k: v for k, v in (data.get("participantsEmails") or {}).items() if k != uid}
        doc.reference.update({
            "participantsUids": nouveaux_participants,
            "roles": nouveaux_roles,
            "participantsEmails": nouveaux_emails,
        })
        _synchroniser_participants_dossier(db, doc.id)

    doc_utilisateur_ref = db.collection("utilisateurs").document(uid)
    _supprimer_sous_collections(doc_utilisateur_ref)
    doc_utilisateur_ref.delete()

    firebase_auth.delete_user(uid)
    return {"ok": True}


_ROLES_ATTRIBUABLES = {"administrateur", "contributeur"}

# Phase 2 (2026-08-31), suite au test réel de Tobie ("tous les administrateurs
# n'ont pas droit de faire tout ce qu'ils veulent comme le créateur, le
# créateur sélectionne ce qui leur est permis lors de la nomination") : les
# trois seuls droits qu'un administrateur peut recevoir. Défaut désactivé
# pour tout nouvel administrateur — voir permissionsAdministrateur ci-dessous.
# - gererParticipants / supprimerDossier : inchangés (ajouter/retirer des
#   participants, supprimer le dossier).
# - modererContenu (ajouté après une question posée à Tobie, suite au red
#   team du plan initial qui laissait par erreur tout administrateur
#   librement modifier/marquer fait/supprimer le contenu de N'IMPORTE QUI,
#   exactement le problème signalé — "un administrateur peut... sans la
#   confirmation du créateur") : sans cette permission, un administrateur
#   est traité comme un simple contributeur face au contenu créé par
#   quelqu'un d'AUTRE (créateur ou contributeur) — passe par la même
#   proposition, ne peut agir librement que sur ce qu'IL a lui-même écrit
#   (voir estGestionnaireContenu, firestore.rules). Avec elle, il retrouve
#   l'accès libre historique (modifier/marquer fait/supprimer, sans
#   proposition) sur tout le contenu du dossier — exactement comme le
#   créateur. Absence totale du champ permissionsAdministrateur sur un
#   dossier = jamais touché par cette fonctionnalité = tout administrateur
#   déjà en place garde ce droit par défaut (rétrocompatibilité).
_PERMISSIONS_ADMINISTRATEUR_VALABLES = {"gererParticipants", "supprimerDossier", "modererContenu"}


def _permissions_valides(permissions) -> bool:
    return isinstance(permissions, list) and all(p in _PERMISSIONS_ADMINISTRATEUR_VALABLES for p in permissions)


@https_fn.on_call(timeout_sec=120)
def gerer_participant_dossier(req: https_fn.CallableRequest) -> dict:
    """`timeout_sec` explicite (trouvé en re-vérifiant ce correctif, via
    /code-review, le 2026-08-31) : cette fonction termine par une
    synchronisation en cascade sur potentiellement toutes les tâches/entrées
    du dossier (_synchroniser_participants_dossier) — le délai par défaut
    d'un `on_call` sans timeout explicite risquerait d'être dépassé sur un
    gros dossier, faisant croire à un échec côté app alors que le retrait/
    ajout a déjà réussi. Même valeur que les autres fonctions à plusieurs
    étapes de ce fichier (supprimer_compte_definitivement).

    Ajoute, retire ou change le rôle d'un participant sur un dossier
    partagé — ou (Phase 2, 2026-08-31) ajuste les permissions à la carte
    d'un administrateur déjà en place. Passe par le SDK Admin (qui ignore
    firestore.rules) car l'opération modifie participantsUids/roles/
    permissionsAdministrateur eux-mêmes — que les règles réservent à
    créateur/administrateur ou créateur seul (voir firestore.rules, règle
    "update" de /dossiers) ; cette fonction reproduit donc elle-même ce
    contrôle d'accès avant d'agir. Champs attendus dans req.data :
    - action : "ajouter" | "retirer" | "changerRole" | "definirPermissionsAdministrateur"
    - dossierId : toujours requis
    - email (ajouter) / uid (retirer, changerRole, definirPermissionsAdministrateur)
    - role (ajouter, changerRole) : "administrateur" | "contributeur"
    - permissions (ajouter/changerRole quand la cible devient administrateur,
      ou definirPermissionsAdministrateur) : sous-liste de
      _PERMISSIONS_ADMINISTRATEUR_VALABLES, défaut [] (aucun droit
      supplémentaire tant que le créateur ne les accorde pas explicitement).

    Lecture+écriture du dossier faites dans une TRANSACTION Firestore
    (trouvé en Red Team le 2026-08-30, voir
    Notes/2026-08-30-redteam-code-collaboration.md, point 4) : sans ça, deux
    administrateurs agissant sur le même dossier presque en même temps
    pouvaient silencieusement s'écraser l'un l'autre (lecture-modification-
    écriture non protégée = perte d'un ajout/retrait).
    """
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")

    donnees = req.data or {}
    action = donnees.get("action")
    dossier_id = donnees.get("dossierId")
    if action not in ("ajouter", "retirer", "changerRole", "definirPermissionsAdministrateur") or not dossier_id:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Paramètres invalides.")

    demandeur_uid = req.auth.uid

    # Résolution de l'email AVANT la transaction : appel à l'API Auth
    # (externe à Firestore), ne dépend pas de l'état du dossier — inutile de
    # le refaire à chaque nouvelle tentative en cas de conflit transactionnel.
    nouvel_uid = None
    nouvel_email = None
    role_ajoute = None
    permissions_ajoutees: list[str] = []
    if action == "ajouter":
        email = (donnees.get("email") or "").strip()
        role_ajoute = donnees.get("role")
        permissions_ajoutees = donnees.get("permissions") or []
        if not email or role_ajoute not in _ROLES_ATTRIBUABLES:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "email/role invalides.")
        if not _permissions_valides(permissions_ajoutees):
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "permissions invalides.")
        try:
            utilisateur = firebase_auth.get_user_by_email(email)
        except firebase_auth.UserNotFoundError:
            raise https_fn.HttpsError(
                https_fn.FunctionsErrorCode.NOT_FOUND, "Aucun compte Vigie avec cet email.", details="aucunCompte"
            )
        nouvel_uid = utilisateur.uid
        nouvel_email = utilisateur.email

    db = firestore.client()
    dossier_ref = db.collection("dossiers").document(dossier_id)

    @firestore.transactional
    def _appliquer(transaction: firestore.Transaction) -> dict:
        dossier_doc = dossier_ref.get(transaction=transaction)
        if not dossier_doc.exists:
            raise https_fn.HttpsError(
                https_fn.FunctionsErrorCode.NOT_FOUND, "Dossier introuvable.", details="dossierIntrouvable"
            )

        dossier_data = dossier_doc.to_dict() or {}
        proprietaire_uid = dossier_data.get("uid")
        participants_uids = list(dossier_data.get("participantsUids") or [proprietaire_uid])
        roles = dict(dossier_data.get("roles") or {proprietaire_uid: "createur"})
        # Emails affichables (uid -> email), pour que l'écran de gestion des
        # participants n'ait jamais besoin d'afficher un uid brut. Auto-réparé
        # ici si absent (dossiers créés avant ce champ, ou créateur jamais
        # encore résolu) plutôt qu'ajouté partout où un dossier est créé.
        participants_emails = dict(dossier_data.get("participantsEmails") or {})
        if proprietaire_uid not in participants_emails:
            try:
                participants_emails[proprietaire_uid] = firebase_auth.get_user(proprietaire_uid).email
            except firebase_auth.UserNotFoundError:
                pass

        role_demandeur = roles.get(demandeur_uid, "createur" if proprietaire_uid == demandeur_uid else None)
        # Se retirer SOI-MÊME reste toujours possible, quel que soit son rôle
        # (décision de Tobie le 2026-08-30, "tranchons alors") : avant ce
        # correctif, un simple contributeur — et même un administrateur, une
        # fois la restriction admin/admin ajoutée — n'avait AUCUN moyen de
        # quitter volontairement un dossier partagé, seuls créateur/
        # administrateur pouvaient appeler "retirer", même pour SE retirer.
        # Le créateur reste seul exception (voir plus bas : il ne peut pas
        # être retiré, ni par lui-même ni par personne — supprimer le dossier
        # est le seul chemin, transférer la propriété reste hors périmètre).
        est_auto_retrait = action == "retirer" and donnees.get("uid") == demandeur_uid
        if not est_auto_retrait and role_demandeur not in ("createur", "administrateur"):
            raise https_fn.HttpsError(
                https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                "Seuls le créateur et les administrateurs peuvent gérer les participants.",
            )

        # Permissions à la carte (Phase 2, 2026-08-31 — voir
        # _PERMISSIONS_ADMINISTRATEUR_VALABLES). `permissions_deja_materialisees`
        # distingue "dossier jamais touché par cette fonctionnalité" (champ
        # absent, administrateur garde tous ses droits historiques) de "le
        # créateur a déjà restreint au moins un administrateur ici" (champ
        # présent, même vide) — indispensable pour ne pas régresser en
        # silence les dossiers existants : voir _appliquer_permissions_ajout
        # plus bas pour la correction de migration (semer les AUTRES
        # administrateurs déjà en place à la première matérialisation).
        permissions_administrateur = dict(dossier_data.get("permissionsAdministrateur") or {})
        permissions_deja_materialisees = "permissionsAdministrateur" in dossier_data
        permissions_modifiees = False

        # Gate additive : un administrateur SANS 'gererParticipants' ne peut
        # plus agir sur les participants — s'ajoute au verrou "jamais sur un
        # autre administrateur" ci-dessous, ne le remplace pas. Ne s'applique
        # que si le créateur a déjà activé cette fonctionnalité sur ce
        # dossier (sinon comportement historique complet, rétrocompatible) ;
        # ne s'applique jamais à definirPermissionsAdministrateur, qui reste
        # strictement créateur-only quoi qu'il arrive (vérifié plus bas).
        if (
            not est_auto_retrait
            and role_demandeur == "administrateur"
            and permissions_deja_materialisees
            and action != "definirPermissionsAdministrateur"
            and "gererParticipants" not in (permissions_administrateur.get(demandeur_uid) or [])
        ):
            raise https_fn.HttpsError(
                https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                "Vous n'avez pas la permission de gérer les participants de ce dossier.",
                details="permissionGererParticipantsRequise",
            )

        def _materialiser_si_besoin(uid_exclu: str) -> None:
            """Première fois que permissionsAdministrateur est écrit sur ce
            dossier : sème les droits complets pour tous les AUTRES
            administrateurs déjà en place, avant d'appliquer la restriction
            demandée — sinon ils perdraient des droits silencieusement au
            moment même où quelqu'un d'autre en gagne (même classe de bug que
            celui déjà trouvé et corrigé sur journalDossier, 2026-08-31)."""
            nonlocal permissions_deja_materialisees
            if permissions_deja_materialisees:
                return
            for uid_p, role_p in roles.items():
                if role_p == "administrateur" and uid_p != uid_exclu:
                    permissions_administrateur.setdefault(uid_p, sorted(_PERMISSIONS_ADMINISTRATEUR_VALABLES))
            permissions_deja_materialisees = True

        # Seul le créateur gère les administrateurs — un administrateur ne
        # peut agir que sur des contributeurs (décision de Tobie le
        # 2026-08-30, en continuant le Red Team : la première version
        # laissait n'importe quel administrateur retirer/rétrograder
        # n'importe quel AUTRE administrateur, y compris entre pairs).
        _MSG_ADMIN_RESERVE_CREATEUR = "Seul le créateur peut gérer un autre administrateur."

        # Pour les notifications instantanées envoyées APRÈS la transaction
        # (voir _notifier_evenements_gestion_participant, appelé plus bas) —
        # qui a été touché, avec quel email/rôle, capturés ICI parce que
        # certains sont sur le point d'être effacés (participants_emails.pop
        # dans "retirer") ou n'existent pas encore avant "ajouter".
        cible_uid_pour_notif = None
        cible_email_pour_notif = None
        nouveau_role_pour_notif = None

        if action == "ajouter":
            if nouvel_uid in participants_uids:
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.ALREADY_EXISTS, "Déjà participant de ce dossier."
                )
            if role_ajoute == "administrateur" and role_demandeur != "createur":
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.PERMISSION_DENIED, _MSG_ADMIN_RESERVE_CREATEUR
                )
            # Phase 2, 2026-09-03 : flux complet d'invitation — au lieu
            # d'ajouter directement l'utilisateur, on écrit une invitation
            # dans utilisateurs/{nouvelUid}/invitations/{dossierId}. La
            # transaction est annulée sans écriture ici (la fonction revient
            # immédiatement après), et l'invitation est écrite HORS transaction
            # ci-dessous. Sécurité : seule une Cloud Function (Admin SDK)
            # écrit/supprime les invitations — l'invité ne peut que les lire.
            return {
                "_action": "invitation_envoyee",
                "_nouvelUid": nouvel_uid,
                "_nomCodeDossier": dossier_data.get("nomCodeDossier") or "Dossier",
                "_roleAjoute": role_ajoute,
                "_permissionsAjoutees": permissions_ajoutees,
                "_demandeurUid": demandeur_uid,
                "_demandeurEmail": participants_emails.get(demandeur_uid) or "",
                "_proprietaireUid": proprietaire_uid,
                "_cibleUid": nouvel_uid,
                "_cibleEmail": nouvel_email,
                "_nouveauRole": role_ajoute,
                "_roleDemandeur": role_demandeur,
                "_estAutoRetrait": False,
            }

        elif action == "retirer":
            cible_uid = donnees.get("uid")
            if not cible_uid:
                raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "uid manquant.")
            if cible_uid == proprietaire_uid:
                # `details` porte un code stable (pas le message français) —
                # traduit côté app selon la langue de l'appareil (trouvé en
                # Red Team le 2026-08-30, point 7 : l'app affichait avant ce
                # message brut tel quel, jamais en anglais).
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                    "Le créateur ne peut pas être retiré du dossier.",
                    details="createurNonRetirable",
                )
            if cible_uid not in participants_uids:
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.NOT_FOUND, "Ce n'est pas un participant.", details="pasParticipant"
                )
            if not est_auto_retrait and roles.get(cible_uid) == "administrateur" and role_demandeur != "createur":
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.PERMISSION_DENIED, _MSG_ADMIN_RESERVE_CREATEUR
                )
            cible_uid_pour_notif = cible_uid
            cible_email_pour_notif = participants_emails.get(cible_uid)
            participants_uids.remove(cible_uid)
            roles.pop(cible_uid, None)
            participants_emails.pop(cible_uid, None)
            if permissions_deja_materialisees and cible_uid in permissions_administrateur:
                permissions_administrateur.pop(cible_uid, None)
                permissions_modifiees = True

        elif action == "changerRole":
            cible_uid = donnees.get("uid")
            role_cible = donnees.get("role")
            if not cible_uid or role_cible not in _ROLES_ATTRIBUABLES:
                raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "uid/role invalides.")
            if cible_uid == proprietaire_uid:
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                    "Le rôle du créateur ne peut pas être changé.",
                    details="createurRoleFixe",
                )
            if cible_uid not in participants_uids:
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.NOT_FOUND, "Ce n'est pas un participant.", details="pasParticipant"
                )
            # Promotion vers administrateur OU changement du rôle d'un
            # administrateur déjà en place : réservé au créateur dans les
            # deux cas (voir _MSG_ADMIN_RESERVE_CREATEUR ci-dessus).
            ancien_role_cible = roles.get(cible_uid)
            if role_demandeur != "createur" and (ancien_role_cible == "administrateur" or role_cible == "administrateur"):
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.PERMISSION_DENIED, _MSG_ADMIN_RESERVE_CREATEUR
                )
            roles[cible_uid] = role_cible

            if role_cible == "administrateur" and ancien_role_cible != "administrateur":
                # Promotion : part de zéro (aucune permission), comme
                # l'ajout direct d'un administrateur — voir action "ajouter".
                permissions = donnees.get("permissions") or []
                if not _permissions_valides(permissions):
                    raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "permissions invalides.")
                _materialiser_si_besoin(cible_uid)
                permissions_administrateur[cible_uid] = sorted(set(permissions))
                permissions_modifiees = True
            elif ancien_role_cible == "administrateur" and role_cible != "administrateur":
                # Rétrogradation : plus besoin d'une entrée de permissions.
                if permissions_deja_materialisees and cible_uid in permissions_administrateur:
                    permissions_administrateur.pop(cible_uid, None)
                    permissions_modifiees = True

            cible_uid_pour_notif = cible_uid
            cible_email_pour_notif = participants_emails.get(cible_uid)
            nouveau_role_pour_notif = role_cible

        else:  # definirPermissionsAdministrateur
            # Strictement créateur-only (décision de Tobie le 2026-08-31,
            # même invariant que "seul le créateur gère un autre
            # administrateur") — pas d'exception même avec 'gererParticipants',
            # c'est justement ce droit-là qui est en train d'être distribué.
            if role_demandeur != "createur":
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.PERMISSION_DENIED, _MSG_ADMIN_RESERVE_CREATEUR
                )
            cible_uid = donnees.get("uid")
            permissions = donnees.get("permissions")
            if not cible_uid or not _permissions_valides(permissions):
                raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "uid/permissions invalides.")
            if roles.get(cible_uid) != "administrateur":
                raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                    "Ce participant n'est pas administrateur.",
                    details="pasAdministrateur",
                )
            _materialiser_si_besoin(cible_uid)
            permissions_administrateur[cible_uid] = sorted(set(permissions))
            permissions_modifiees = True

        donnees_maj = {
            "participantsUids": participants_uids,
            "roles": roles,
            "participantsEmails": participants_emails,
        }
        if permissions_modifiees:
            donnees_maj["permissionsAdministrateur"] = permissions_administrateur
        transaction.update(dossier_ref, donnees_maj)
        return {
            "participantsUids": participants_uids,
            "roles": roles,
            "participantsEmails": participants_emails,
            "permissionsAdministrateur": permissions_administrateur,
            # Champs internes, jamais renvoyés tels quels au téléphone (voir
            # plus bas, retirés avant le `return {"ok": True, **resultat}`) —
            # juste ce qu'il faut pour décider quelles notifications
            # instantanées envoyer une fois la transaction validée.
            "_nomCodeDossier": dossier_data.get("nomCodeDossier") or "Dossier",
            "_roleDemandeur": role_demandeur,
            "_estAutoRetrait": est_auto_retrait,
            "_demandeurEmail": participants_emails.get(demandeur_uid) or dossier_data.get(
                "participantsEmails", {}
            ).get(demandeur_uid) or "",
            "_cibleUid": cible_uid_pour_notif,
            "_cibleEmail": cible_email_pour_notif,
            "_nouveauRole": nouveau_role_pour_notif,
            "_proprietaireUid": proprietaire_uid,
        }

    resultat = _appliquer(db.transaction())

    # Si l'action est "ajouter", on crée une invitation hors transaction
    # (la transaction ci-dessus a été annulée sans écriture Firestore dans ce cas).
    if action == "ajouter" and resultat.get("_action") == "invitation_envoyee":
        invitation_ref = (
            db.collection("utilisateurs")
            .document(resultat["_nouvelUid"])
            .collection("invitations")
            .document(dossier_id)
        )
        invitation_ref.set({
            "dossierId": dossier_id,
            "nomCodeDossier": resultat["_nomCodeDossier"],
            "role": resultat["_roleAjoute"],
            "permissions": resultat["_permissionsAjoutees"],
            "invitePar": resultat["_demandeurUid"],
            "inviteParEmail": resultat["_demandeurEmail"],
            "creeA": firestore.SERVER_TIMESTAMP,
        })
        # Notifier l'invité (push + historique in-app)
        _notifier_evenement(
            db,
            resultat["_nouvelUid"],
            type_evenement="invitation",
            corps=f"\"{resultat['_nomCodeDossier']}\" : {resultat['_demandeurEmail']} t'invite à collaborer.",
            dossier_id=dossier_id,
        )
        return {"ok": True, "invitationEnvoyee": True}

    # Seuls ajouter/retirer changent participantsUids — changerRole et
    # definirPermissionsAdministrateur ne touchent jamais qui a accès, juste
    # son rôle/ses permissions, inutile de resynchroniser tâches/journal.
    if action in ("ajouter", "retirer"):
        _synchroniser_participants_dossier(db, dossier_id)

    _notifier_evenements_gestion_participant(db, action, demandeur_uid, dossier_id, resultat)

    resultat_public = {k: v for k, v in resultat.items() if not k.startswith("_")}
    return {"ok": True, **resultat_public}

@https_fn.on_call(timeout_sec=120)
def supprimer_dossier_partage(req: https_fn.CallableRequest) -> dict:
    """Supprime un dossier partagé et tout son contenu (tâches, journal) en cascade.
    L'appelant doit être le créateur OU un administrateur ayant la permission 'supprimerDossier'.
    Exécuté avec le SDK Admin pour outrepasser les règles de sécurité, car un administrateur
    sans 'modererContenu' n'a pas le droit de supprimer les tâches/entrées des autres
    individuellement (Firestore rules)."""
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")

    donnees = req.data or {}
    dossier_id = donnees.get("dossierId")
    if not dossier_id:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "dossierId manquant.")

    db = firestore.client()
    dossier_ref = db.collection("dossiers").document(dossier_id)
    dossier_doc = dossier_ref.get()

    if not dossier_doc.exists:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.NOT_FOUND, "Dossier introuvable.")

    dossier_data = dossier_doc.to_dict() or {}
    demandeur_uid = req.auth.uid
    proprietaire_uid = dossier_data.get("uid")

    if demandeur_uid != proprietaire_uid:
        # Vérifier si c'est un administrateur avec le droit de supprimer
        roles = dossier_data.get("roles") or {}
        if roles.get(demandeur_uid) != "administrateur":
             raise https_fn.HttpsError(
                https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                "Seul le créateur ou un administrateur peut supprimer ce dossier."
            )
        
        # Vérifier les permissions à la carte s'il y en a
        if "permissionsAdministrateur" in dossier_data:
            permissions = dossier_data["permissionsAdministrateur"].get(demandeur_uid) or []
            if "supprimerDossier" not in permissions:
                 raise https_fn.HttpsError(
                    https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                    "Vous n'avez pas la permission de supprimer ce dossier."
                )

    # Suppression en cascade (tâches, journal, puis dossier)
    _supprimer_par_lots(db.collection("taches").where("dossierId", "==", dossier_id))
    _supprimer_par_lots(db.collection("journalDossier").where("dossierId", "==", dossier_id))
    dossier_ref.delete()

    return {"ok": True}


@https_fn.on_call(timeout_sec=120)
def repondre_invitation(req: https_fn.CallableRequest) -> dict:
    """Accepter ou refuser une invitation à rejoindre un dossier partagé.
    Champs attendus dans req.data :
    - dossierId : identifiant du dossier (aussi l'ID du document d'invitation)
    - reponse : \"accepter\" | \"refuser\"

    Sécurité : seul l'invité (request.auth.uid == uid de l'invitation) peut
    répondre — l'invitation est stockée dans utilisateurs/{uid}/invitations/
    dont seul le propriétaire est userId, et cette fonction vérifie auth.uid
    avant tout accès. Le SDK Admin ignore les règles Firestore, mais cette
    vérification reproduit l'invariant de propriété côté serveur.

    Si accepté : applique l'ajout réel (même logique que l'ancien "ajouter"
    direct dans gerer_participant_dossier), synchronise les tâches/journal,
    et supprime l'invitation. Si refusé : supprime simplement l'invitation.
    """
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Non connecté.")

    donnees = req.data or {}
    dossier_id = donnees.get("dossierId")
    reponse = donnees.get("reponse")
    if not dossier_id or reponse not in ("accepter", "refuser"):
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Paramètres invalides.")

    invite_uid = req.auth.uid
    db = firestore.client()

    # Lecture de l'invitation
    invitation_ref = (
        db.collection("utilisateurs")
        .document(invite_uid)
        .collection("invitations")
        .document(dossier_id)
    )
    invitation_doc = invitation_ref.get()
    if not invitation_doc.exists:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.NOT_FOUND, "Invitation introuvable ou déjà traitée."
        )

    invitation_data = invitation_doc.to_dict() or {}
    role_ajoute = invitation_data.get("role", "contributeur")
    permissions_ajoutees: list[str] = invitation_data.get("permissions") or []
    invite_par_uid = invitation_data.get("invitePar")
    invite_par_email = invitation_data.get("inviteParEmail", "")
    nom_code_dossier = invitation_data.get("nomCodeDossier", "Dossier")

    # Supprimer l'invitation dans tous les cas (qu'on accepte ou refuse)
    invitation_ref.delete()

    if reponse == "refuser":
        # Notifier l'invitant du refus
        if invite_par_uid:
            _notifier_evenement(
                db,
                invite_par_uid,
                type_evenement="invitationRefusee",
                corps=f"\"{nom_code_dossier}\" : l'invitation a été refusée.",
                dossier_id=dossier_id,
            )
        return {"ok": True, "refuse": True}

    # Acceptation : ajouter réellement le participant (avec transaction)
    dossier_ref = db.collection("dossiers").document(dossier_id)

    @firestore.transactional
    def _appliquer_acceptation(transaction: firestore.Transaction) -> dict:
        dossier_doc = dossier_ref.get(transaction=transaction)
        if not dossier_doc.exists:
            raise https_fn.HttpsError(
                https_fn.FunctionsErrorCode.NOT_FOUND, "Dossier introuvable.", details="dossierIntrouvable"
            )

        dossier_data = dossier_doc.to_dict() or {}
        proprietaire_uid = dossier_data.get("uid")
        participants_uids = list(dossier_data.get("participantsUids") or [proprietaire_uid])
        roles = dict(dossier_data.get("roles") or {proprietaire_uid: "createur"})
        participants_emails = dict(dossier_data.get("participantsEmails") or {})
        permissions_administrateur = dict(dossier_data.get("permissionsAdministrateur") or {})
        permissions_deja_materialisees = "permissionsAdministrateur" in dossier_data

        # Vérification anti-doublon (l'invitation a pu rester en attente
        # pendant que l'utilisateur était ajouté par un autre chemin)
        if invite_uid in participants_uids:
            return {"_dejaMembre": True}

        # Récupérer l'email de l'invité pour participantsEmails
        try:
            invitee_user = firebase_auth.get_user(invite_uid)
            invitee_email = invitee_user.email
        except firebase_auth.UserNotFoundError:
            invitee_email = None

        participants_uids.append(invite_uid)
        roles[invite_uid] = role_ajoute
        participants_emails[invite_uid] = invitee_email

        permissions_modifiees = False
        if role_ajoute == "administrateur":
            if not permissions_deja_materialisees:
                for uid_p, role_p in roles.items():
                    if role_p == "administrateur" and uid_p != invite_uid:
                        permissions_administrateur.setdefault(uid_p, sorted(_PERMISSIONS_ADMINISTRATEUR_VALABLES))
            permissions_administrateur[invite_uid] = sorted(set(permissions_ajoutees))
            permissions_modifiees = True

        donnees_maj = {
            "participantsUids": participants_uids,
            "roles": roles,
            "participantsEmails": participants_emails,
        }
        if permissions_modifiees:
            donnees_maj["permissionsAdministrateur"] = permissions_administrateur
        transaction.update(dossier_ref, donnees_maj)
        return {
            "_proprietaireUid": proprietaire_uid,
            "_inviteEmail": invitee_email,
        }

    resultat = _appliquer_acceptation(db.transaction())

    if resultat.get("_dejaMembre"):
        return {"ok": True, "dejaMembre": True}

    # Synchroniser participantsUids sur les tâches/journal
    _synchroniser_participants_dossier(db, dossier_id)

    # Notifier l'invitant de l'acceptation
    if invite_par_uid:
        invite_email = resultat.get("_inviteEmail") or "L'invité"
        _notifier_evenement(
            db,
            invite_par_uid,
            type_evenement="invitationAcceptee",
            corps=f"\"{nom_code_dossier}\" : {invite_email} a accepté de collaborer.",
            dossier_id=dossier_id,
        )

    return {"ok": True, "accepte": True}
