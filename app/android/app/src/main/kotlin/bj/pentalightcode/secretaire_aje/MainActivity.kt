package bj.pentalightcode.secretaire_aje

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (biométrie) exige FlutterFragmentActivity, pas FlutterActivity —
// sans ça, authenticate()/canCheckBiometrics échouent silencieusement
// (trouvé le 2026-08-18 : c'était la cause du verrou biométrique inopérant
// depuis le début, masquée par un try/catch qui avalait l'erreur).
class MainActivity : FlutterFragmentActivity()
