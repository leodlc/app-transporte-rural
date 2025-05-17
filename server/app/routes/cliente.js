const express = require('express');
const router = express.Router();

const { getAllClients, getClientByName,getClientById, createClient, updateClient, deleteClient, updateClientFCMToken, sendPushNotification } = require('../controllers/cliente');

router.get('/', getAllClients);

router.get('/nombre/:nombreCliente', getClientByName);

router.post('/createClient', createClient);

router.get('/id/:id', getClientById);

router.patch('/:id', updateClient);

router.patch('/:id/tokenFCM', updateClientFCMToken); 
router.delete('/:id', deleteClient);
router.post('/:id/sendPushNotification', sendPushNotification);

module.exports = router;