"""Publie le numéro de la dernière version de l'app (via la fonction serveur
`publier_version_admin`, protégée par secret) pour que l'app sache qu'une
mise à jour est disponible (voir lib/services/version_service.dart). À
exécuter après chaque nouveau `flutter build apk` + republication de l'APK.

Le secret doit être passé par la variable d'environnement
ADMIN_PUBLICATION_SECRET (jamais en argument, pour ne pas rester dans
l'historique du shell).

Usage :
    ADMIN_PUBLICATION_SECRET=... python3 scripts/publier_version.py 1.0.1 2
    (1.0.1 = version affichée, 2 = build number, doit correspondre au +N
    de pubspec.yaml)
"""

import os
import sys

import requests

_URL_FONCTION = "https://us-central1-secretaire-aje.cloudfunctions.net/publier_version_admin"
_URL_APK = "https://vigie.pentalightcode.com/telecharger/Vigie.apk"


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage : publier_version.py <version ex: 1.0.1> <build ex: 2>")
        sys.exit(1)

    secret = os.environ.get("ADMIN_PUBLICATION_SECRET")
    if not secret:
        print("Variable d'environnement ADMIN_PUBLICATION_SECRET manquante.")
        sys.exit(1)

    version, build = sys.argv[1], int(sys.argv[2])

    reponse = requests.post(
        _URL_FONCTION,
        json={"version": version, "build": build, "urlApk": _URL_APK, "secret": secret},
        timeout=15,
    )
    print(reponse.status_code, reponse.text)
    reponse.raise_for_status()


if __name__ == "__main__":
    main()
