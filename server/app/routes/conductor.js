const express = require('express');
const router = express.Router();

const { getAllDrivers, getDriverByName, getDriverById ,createDriver, updateDriver, deleteDriver, updateDriverFCMToken, actualizarUbicacionActiva } = require('../controllers/conductor');

router.get('/', getAllDrivers);

router.get('/nombre/:nombreConductor', getDriverByName);

router.post('/createDriver', createDriver);

router.get('/id/:id', getDriverById);

router.patch('/:id', updateDriver);

router.delete('/:id', deleteDriver);

//router.patch('/:id/ubicacion', updateDriverLocationRealtime);

router.patch('/:id/tokenFCM', updateDriverFCMToken);

router.patch('/:id/ubicacionActiva', actualizarUbicacionActiva);

//router.get('/disponibles', getAvailableDrivers);

//router.post('/asignarPedido', assignOrderToDriver);

//router.post('/:id/sendPushNotification', sendPushNotificationToConductor);

module.exports = router;