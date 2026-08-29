import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Un compte Google connecté — aucun rôle prédéfini côté app (revu le
/// 2026-08-21, sur retour de Tobie après test réel : une première tentative
/// avec deux connexions nommées "email"/"agenda" le même jour a été jugée
/// pas intuitive). L'utilisateur peut connecter autant de comptes qu'il veut
/// et leur donner un libellé personnalisé pour s'y retrouver — ça ne change
/// rien à ce que le serveur en fait, chaque compte est scanné de la même
/// façon (Gmail + Tasks + Calendar).
class ConnexionGoogle {
  const ConnexionGoogle({required this.id, required this.emailConnecte, required this.libelle});

  final String id;
  final String emailConnecte;
  final String libelle;

  /// Le libellé personnalisé si renseigné, sinon l'adresse connectée —
  /// jamais vide même si les deux le sont (connexion créée avant le
  /// correctif du 2026-08-21, à reconnecter pour retrouver la vraie adresse).
  String affichage(BuildContext context) {
    if (libelle.isNotEmpty) return libelle;
    if (emailConnecte.isNotEmpty) return emailConnecte;
    return AppLocalizations.of(context)!.connexionGoogleAdresseInconnue;
  }

  factory ConnexionGoogle.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConnexionGoogle(
      id: doc.id,
      emailConnecte: data['emailConnecte'] as String? ?? '',
      libelle: data['libelle'] as String? ?? '',
    );
  }
}
