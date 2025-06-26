const express = require('express');
const router = express.Router();

const { getAllClients, getClientByName,getClientById, createClient, updateClient, deleteClient, updateClientFCMToken, sendPushNotification, clearClientFCMToken } = require('../controllers/cliente');

router.get('/', getAllClients);

router.get('/nombre/:nombreCliente', getClientByName);

router.post('/createClient', createClient);

router.get('/id/:id', getClientById);

router.patch('/:id', updateClient);

router.patch('/:id/tokenFCM', updateClientFCMToken); 
router.delete('/:id', deleteClient);
router.post('/:id/sendPushNotification', sendPushNotification);

router.patch('/:id/clear-token', clearClientFCMToken);



module.exports = router;