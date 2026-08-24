// Test minimal : vérifie que l'écran de connexion s'affiche correctement.
// (Note : on ne teste pas SecretaireAjeApp() directement ici, car son
// démarrage dépend de Firebase.initializeApp() — pas encore de mocks Firebase
// en place. À ajouter quand on mettra en place une vraie suite de tests.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretaire_aje/screens/connexion_screen.dart';

void main() {
  testWidgets('L\'écran de connexion affiche le titre et le champ email', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConnexionScreen()));
    await tester.pump();

    expect(find.text('Secrétaire AJE'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
