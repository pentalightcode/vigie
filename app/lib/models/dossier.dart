import 'package:cloud_firestore/cloud_firestore.dart';

/// Un dossier (affaire, réunion ou rendez-vous), désigné par un nom de code
/// choisi par le père — jamais le vrai nom des parties ou la nature de l'affaire.
class Dossier {
  Dossier({
    required this.id,
    required this.uid,
    required this.nomCode,
    this.dateEvenement,
    this.notePrivee,
    List<String>? participantsUids,
    Map<String, String>? roles,
    this.participantsEmails = const {},
    this.permissionsAdministrateur = const {},
    this.permissionsAdministrateurDefinies = false,
  })  : participantsUids = participantsUids ?? [uid],
        roles = roles ?? {uid: 'createur'};

  final String id;
  final String uid;
  final String nomCode;
  final DateTime? dateEvenement; // date de l'audience, du rendez-vous, etc.
  final String? notePrivee; // chiffré côté téléphone avant écriture (à venir)

  /// Qui a accès à ce dossier (ajouté le 2026-08-29, refonte "travail de
  /// groupe" — voir Notes/2026-08-29-redteam-collaboration-multi-angles.md).
  /// Dénormalisé pour permettre les requêtes "mes dossiers" (array-contains)
  /// et pour que les règles Firestore n'aient besoin d'aucune lecture
  /// supplémentaire. Copié sur chaque tâche/entrée de journal du dossier
  /// pour la même raison (voir ChiffrementNotesService... non, voir
  /// firestore.rules pour le détail du modèle).
  final List<String> participantsUids;

  /// Rôle de chaque participant : 'createur' | 'administrateur' |
  /// 'contributeur'. Seuls créateur/administrateur peuvent modifier qui a
  /// accès ou supprimer le dossier — le reste (nom, date) reste modifiable
  /// par tout participant (accès complet choisi par Tobie).
  final Map<String, String> roles;

  /// Email de chaque participant (uid -> email), pour l'affichage — écrit
  /// UNIQUEMENT par la fonction serveur `gerer_participant_dossier` (jamais
  /// depuis le téléphone, voir firestore.rules). Peut être incomplet sur un
  /// dossier jamais géré via cette fonction (dossier solo, jamais partagé).
  final Map<String, String> participantsEmails;

  /// Permissions à la carte de chaque administrateur (Phase 2, 2026-08-31 —
  /// voir estGestionnaireContenu ci-dessous et firestore.rules). Écrit
  /// UNIQUEMENT par `gerer_participant_dossier` (action
  /// definirPermissionsAdministrateur), jamais depuis le téléphone.
  final Map<String, List<String>> permissionsAdministrateur;

  /// Distingue "dossier jamais touché par cette fonctionnalité" (champ
  /// totalement absent côté Firestore : `permissionsAdministrateur` reste
  /// `{}` ci-dessus, mais ça ne veut PAS dire "tout le monde restreint" —
  /// voir estGestionnaireContenu) de "le créateur a déjà défini au moins une
  /// restriction sur ce dossier" (champ présent, même vide pour un uid
  /// donné). Sans cette distinction, impossible de savoir côté client si un
  /// administrateur sans entrée explicite garde ses droits historiques ou
  /// est réellement restreint.
  final bool permissionsAdministrateurDefinies;

  /// Miroir client de `estGestionnaireContenu()` (firestore.rules) et de
  /// `_PERMISSIONS_ADMINISTRATEUR_VALABLES` (functions/main.py), Phase 2,
  /// 2026-08-31 — duplication volontaire (défense en profondeur, comme le
  /// reste du modèle de permission de ce projet, voir Notes) : décide si
  /// `participantUid` a un accès libre au contenu créé par quelqu'un
  /// D'AUTRE (le créateur, ou lui-même, restent toujours libres sur leur
  /// propre contenu, voir `estAuteurTacheOuGestionnaire`/
  /// `estAuteurOuGestionnaire` côté écran) — sinon il doit passer par une
  /// proposition. Le serveur reste seul juge final, ceci ne sert qu'à
  /// afficher les bons boutons/badges sans attendre un aller-retour.
  bool estGestionnaireContenu(String participantUid) {
    final role = roleDe(participantUid);
    if (role == 'createur') return true;
    if (role != 'administrateur') return false;
    if (!permissionsAdministrateurDefinies) return true; // rétrocompatibilité
    return (permissionsAdministrateur[participantUid] ?? const []).contains('modererContenu');
  }

  /// Miroir client de `peutSupprimerDossier()` (firestore.rules), Phase 2,
  /// 2026-08-31 — même logique de permission à la carte que ci-dessus, mais
  /// pour SUPPRIMER LE DOSSIER lui-même (`supprimerDossier`, pas
  /// `modererContenu`) : un droit distinct, un administrateur peut avoir
  /// l'un sans l'autre.
  bool peutSupprimer(String participantUid) {
    final role = roleDe(participantUid);
    if (role == 'createur') return true;
    if (role != 'administrateur') return false;
    if (!permissionsAdministrateurDefinies) return true; // rétrocompatibilité
    return (permissionsAdministrateur[participantUid] ?? const []).contains('supprimerDossier');
  }

  factory Dossier.depuisDocument(DocumentSnapshot doc) {
    // Vérifié AVANT le cast (trouvé en re-vérifiant ce correctif, via
    // /code-review, le 2026-08-31) : si le dossier a été SUPPRIMÉ (pas
    // seulement un retrait d'accès), Firestore livre un instantané avec
    // `exists: false` — `doc.data()` renvoie alors `null`, pas une Map, et
    // `as Map<String, dynamic>` plantait avec un `TypeError` générique.
    // `VueAccesRevoque` ne reconnaissait que les `FirebaseException` de code
    // `permission-denied` comme "accès révoqué" — un `TypeError` y affichait
    // à tort le message "erreur réseau" au lieu de "tu n'as plus accès",
    // exactement le cas que ce widget avait été conçu pour distinguer.
    if (!doc.exists) {
      throw DossierIntrouvableException(doc.id);
    }
    final data = doc.data() as Map<String, dynamic>;
    final uid = data['uid'] as String;
    return Dossier(
      id: doc.id,
      uid: uid,
      nomCode: data['nomCode'] as String,
      dateEvenement: (data['dateEvenement'] as Timestamp?)?.toDate(),
      notePrivee: data['notePrivee'] as String?,
      // Rétrocompatibilité : dossiers créés avant le 2026-08-29, qui n'ont
      // pas encore ces champs — le créateur d'origine reste seul participant.
      participantsUids: (data['participantsUids'] as List<dynamic>?)?.cast<String>() ?? [uid],
      roles: (data['roles'] as Map<String, dynamic>?)?.cast<String, String>() ?? {uid: 'createur'},
      participantsEmails: (data['participantsEmails'] as Map<String, dynamic>?)?.cast<String, String>() ?? const {},
      permissionsAdministrateur: (data['permissionsAdministrateur'] as Map<String, dynamic>?)?.map(
            (cle, valeur) => MapEntry(cle, (valeur as List<dynamic>).cast<String>()),
          ) ??
          const {},
      permissionsAdministrateurDefinies: data.containsKey('permissionsAdministrateur'),
    );
  }

  Map<String, dynamic> versDocument() {
    return {
      'uid': uid,
      'nomCode': nomCode,
      'dateEvenement': dateEvenement != null ? Timestamp.fromDate(dateEvenement!) : null,
      'notePrivee': notePrivee,
      'participantsUids': participantsUids,
      'roles': roles,
      'creeLe': FieldValue.serverTimestamp(),
    };
  }

  /// Rôle d'un uid sur ce dossier — repli sur 'createur' pour le
  /// propriétaire d'un dossier créé avant le 29/08 (pas encore de `roles`,
  /// couvert de toute façon par la valeur par défaut du constructeur).
  /// Centralisé ici (trouvé en Red Team le 2026-08-30, via /code-review)
  /// après avoir vu cette même expression dupliquée dans
  /// `dossier_detail_screen.dart` et `participants_dossier_screen.dart` —
  /// deux copies auraient pu diverger silencieusement si ce repli changeait
  /// un jour dans une seule des deux.
  ///
  /// Si l'uid n'est ni le propriétaire ni dans `roles` (ne devrait jamais
  /// arriver pour un vrai participant, `participantsUids`/`roles` étant
  /// toujours synchronisés ensemble), renvoie un repli qui ne correspond à
  /// AUCUN rôle réel plutôt que 'contributeur' par optimisme (trouvé en
  /// re-vérifiant ce correctif, via /code-review, le 2026-08-31) : le
  /// `role()` équivalent côté firestore.rules renvoie `null` (aucun droit)
  /// dans ce même cas — un repli client plus permissif que le serveur
  /// aurait pu laisser croire à un accès que le serveur refuserait.
  String roleDe(String participantUid) =>
      roles[participantUid] ?? (uid == participantUid ? 'createur' : 'aucun');

  Dossier copierAvec({String? nomCode, DateTime? dateEvenement, bool effacerDate = false}) {
    return Dossier(
      id: id,
      uid: uid,
      nomCode: nomCode ?? this.nomCode,
      dateEvenement: effacerDate ? null : (dateEvenement ?? this.dateEvenement),
      notePrivee: notePrivee,
      participantsUids: participantsUids,
      roles: roles,
      participantsEmails: participantsEmails,
      permissionsAdministrateur: permissionsAdministrateur,
      permissionsAdministrateurDefinies: permissionsAdministrateurDefinies,
    );
  }
}

/// Levée par `Dossier.depuisDocument` quand le document n'existe plus
/// (supprimé) — distincte d'une `FirebaseException` de permission, pour que
/// `VueAccesRevoque` puisse traiter les deux comme "ce dossier n'est plus
/// disponible pour toi" sans confondre ça avec une vraie erreur réseau.
class DossierIntrouvableException implements Exception {
  const DossierIntrouvableException(this.dossierId);
  final String dossierId;

  @override
  String toString() => 'Dossier introuvable (supprimé ou jamais existé) : $dossierId';
}
