import firebase_admin
from firebase_admin import credentials, firestore
import os
os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = ""
os.environ["FIRESTORE_EMULATOR_HOST"] = ""
firebase_admin.initialize_app()
db = firestore.client()
try:
    query = db.collection("taches").where("dossierId", "==", "test")
    print("3 arguments works!")
except Exception as e:
    print("Error:", e)
