const admin = require("firebase-admin");
const path = require("path");

// Cargar credenciales desde el archivo JSON
const serviceAccount = require(path.join(__dirname, "tranporte-rural-firebase-adminsdk-fbsvc-e63ab2c41b.json"));
const FIREBASE_DB_URL = process.env.FIREBASE_DB_URL;
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  //databaseURL: FIREBASE_DB_URL
});

const firestore = admin.firestore();
const messaging = admin.messaging();

module.exports = { admin, firestore, messaging };