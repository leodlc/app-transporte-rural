const express = require('express');
const router = express.Router();

const {createFrase,getFraseAleatoria,getAllFrases,deleteFraseById} = require('../controllers/frase');

router.post('/createFrase', createFrase); // Ruta para crear una frase
router.get('/aleatoria', getFraseAleatoria); // Ruta para obtener una frase aleatoria
router.get('/', getAllFrases); // Ruta para obtener todas las frases
router.delete('/:id', deleteFraseById); // Ruta para eliminar una frase por ID

module.exports = router;