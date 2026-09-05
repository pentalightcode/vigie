import re

# 1. assistant_service.dart
with open('app/lib/services/assistant_service.dart', 'r') as f:
    content = f.read()

content = re.sub(r"import '\.\./services/chiffrement_notes_service\.dart';\n", "", content)

assistant_old = """          var texte = entree.texte;
          if (entree.chiffre) {
            if (!ChiffrementNotesService.instance.estDeverrouille) continue;
            texte = await ChiffrementNotesService.instance.dechiffrer(texte);
          }
          entreesContext.add("${entree.creeLe.toIso8601String()} - ${entree.creePar} (${entree.type.name}): $texte");"""
assistant_new = """          entreesContext.add("${entree.creeLe.toIso8601String()} - ${entree.creePar} (${entree.type.name}): ${entree.texte}");"""
content = content.replace(assistant_old, assistant_new)

with open('app/lib/services/assistant_service.dart', 'w') as f:
    f.write(content)


# 2. auth_service.dart
with open('app/lib/services/auth_service.dart', 'r') as f:
    content = f.read()

content = re.sub(r"import 'chiffrement_notes_service\.dart';\n", "", content)
content = re.sub(r"\s*ChiffrementNotesService\.instance\.reinitialiser\(\);\n", "\n", content)

with open('app/lib/services/auth_service.dart', 'w') as f:
    f.write(content)


# 3. utilisateur_service.dart
with open('app/lib/services/utilisateur_service.dart', 'r') as f:
    content = f.read()

content = re.sub(r"import 'chiffrement_notes_service\.dart';\n", "", content)
content = re.sub(r"\s*ChiffrementNotesService\.instance\.reinitialiser\(\);\n", "\n", content)

with open('app/lib/services/utilisateur_service.dart', 'w') as f:
    f.write(content)

