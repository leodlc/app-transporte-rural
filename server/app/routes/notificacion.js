// routes/notificacion.js
const express = require('express');
const router = express.Router();
const { actualizarTokenFCM, enviarNotificacion } = require('../controllers/notificacion');

router.post('/token', actualizarTokenFCM);
router.post('/enviar', enviarNotificacion); // <-- NUEVA RUTA

module.exports = router;
