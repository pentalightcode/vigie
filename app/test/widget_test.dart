// Test minimal : vérifie que l'écran de connexion s'affiche correctement.
// (Note : on ne teste pas SecretaireAjeApp() directement ici, car son
// démarrage dépend de Firebase.initializeApp() — pas encore de mocks Firebase
// en place. À ajouter quand on mettra en place une vraie suite de tests.)
//
// Trouvé cassé (deux raisons distinctes) en simulant l'arrivée d'un nouveau
// collaborateur le 31/08/2026 — `flutter test` est le premier réflexe naturel
// pour vérifier une installation, et ce test échouait depuis un moment sans
// rapport avec l'environnement de qui l'exécute :
// 1. Vérifiait encore l'ancien nom "Secrétaire AJE", jamais mis à jour après
//    le renommage en "Vigie".
// 2. `MaterialApp` construit sans `localizationsDelegates`/`supportedLocales`
//    (jamais mis à jour après l'introduction de l'i18n le 29/08/2026) — fait
//    planter `AppLocalizations.of(context)!` dans `ConnexionScreen`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretaire_aje/l10n/app_localizations.dart';
import 'package:secretaire_aje/screens/connexion_screen.dart';

void main() {
  testWidgets('L\'écran de connexion affiche le titre et le champ email', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ConnexionScreen(),
    ));
    await tester.pump();

    expect(find.text('Vigie'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
