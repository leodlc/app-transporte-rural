const express = require('express');
const router = express.Router();

const { verificarViajeActivo } = require('../controllers/viajeController');

router.get('/verificar/:id', verificarViajeActivo);

module.exports = router;