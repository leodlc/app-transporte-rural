const express = require('express');
const router = express.Router();
const { verificarEmail } = require('../controllers/verifyEmail');

router.post('/verificar-mail', verificarEmail);

module.exports = router;
