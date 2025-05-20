const express = require('express');
const router = express.Router();
const {
  createCooperativa,
  getCooperativaById,
  getAllCooperativas,
  updateCooperativa,
  deleteCooperativa
} = require('../controllers/cooperativaController');

router.post('/', createCooperativa);
router.get('/', getAllCooperativas);
router.get('/:id', getCooperativaById);
router.put('/:id', updateCooperativa);
router.delete('/:id', deleteCooperativa);

module.exports = router;
