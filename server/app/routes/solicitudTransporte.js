const express = require('express');
const router = express.Router();
const {
  crearSolicitud,
  getSolicitudesPorConductor,
  actualizarEstadoSolicitud,
  existeSolicitudPendiente
} = require('../controllers/solicitudTransporte');

// Crear una solicitud
router.post('/crear', crearSolicitud);

// Obtener solicitudes pendientes por conductor
router.get('/por-conductor/:conductorId', getSolicitudesPorConductor);

// Actualizar estado de una solicitud (aceptar/rechazar/finalizar)
router.patch('/:id/estado', actualizarEstadoSolicitud);

router.get('/existe-pendiente', existeSolicitudPendiente);


module.exports = router;
