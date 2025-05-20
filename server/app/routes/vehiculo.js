const express = require('express');
const router = express.Router();

const { getAllVehiculos, getVehiculoByPlaca, createVehiculo, updateVehiculo, deleteVehiculo } = require('../controllers/vehiculo');

router.get('/', getAllVehiculos);

router.get('/placa/:placa', getVehiculoByPlaca);

router.post('/createVehiculo', createVehiculo);

router.patch('/:id', updateVehiculo);

router.delete('/:id', deleteVehiculo);

module.exports = router;