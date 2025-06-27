const admin = require("firebase-admin");
const path = require("path");

// Cargar credenciales desde el archivo JSON
const serviceAccountPath = path.join(__dirname, process.env.FIREBASE_ARCHIVO_CUENTA_SERVICIO);
const serviceAccount = require(serviceAccountPath);
const FIREBASE_DB_URL = process.env.FIREBASE_DB_URL;
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  //databaseURL: FIREBASE_DB_URL
});

const firestore = admin.firestore();
const messaging = admin.messaging();

module.exports = { admin, firestore, messaging };