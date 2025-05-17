const express = require('express');
const router = express.Router();
const { createAdmin, getAdminById, sendPushNotificationToAdmin, updateAdminFCMToken, getAllAdmins } = require('../controllers/admin');

router.post('/register', createAdmin); // Ruta para crear un admin

router.get('/id/:id', getAdminById); // Ruta para obtener un admin por su ID

router.post('/:id/sendPushNotification', sendPushNotificationToAdmin);// Ruta para enviar notificación push a un admin

router.patch('/:id/tokenFCM', updateAdminFCMToken); // Ruta para actualizar el tokenFCM de un admin

router.get('/', getAllAdmins); // Ruta para obtener todos los admins

module.exports = router;