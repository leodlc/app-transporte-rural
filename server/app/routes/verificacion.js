const express = require('express');
const router = express.Router();
const { verificarCodigo } = require('../controllers/verificacion');

router.post('/codigo', verificarCodigo);

module.exports = router;
