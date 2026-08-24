import 'package:flutter/material.dart';

/// Identifie la source d'une proposition à partir du champ `expediteur` —
/// "Google Tasks"/"Google Calendar" sont des libellés fixes posés par le
/// serveur, tout le reste est une adresse email (Gmail). Inspiré des
/// calendriers colorés de Google Agenda, transformé pour Vigie : coder les
/// Propositions par origine plutôt que par calendrier (demandé par Tobie le
/// 2026-08-20).
enum SourceProposition { gmail, tasks, calendar }

({SourceProposition source, String libelle, Color couleur, IconData icone}) infosSource(String expediteur) {
  return switch (expediteur) {
    'Google Tasks' => (
        source: SourceProposition.tasks,
        libelle: 'Google Tasks',
        couleur: Colors.blue,
        icone: Icons.check_circle_outline,
      ),
    'Google Calendar' => (
        source: SourceProposition.calendar,
        libelle: 'Google Calendar',
        couleur: Colors.deepOrange,
        icone: Icons.event,
      ),
    _ => (
        source: SourceProposition.gmail,
        libelle: 'Gmail',
        couleur: Colors.red,
        icone: Icons.email_outlined,
      ),
  };
}
