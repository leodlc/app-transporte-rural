const SolicitudTransporte = require('../models/solicitudTransporte');
const { httpError } = require('../helpers/handleError');
const Cliente = require('../models/cliente');


// Crear una nueva solicitud
const crearSolicitud = async (req, res) => {
  try {
    const { clienteId, conductorId } = req.body;

    if (!clienteId || !conductorId) {
      return res.status(400).json({ error: 'clienteId y conductorId son requeridos' });
    }

    const nuevaSolicitud = await SolicitudTransporte.create({ clienteId, conductorId });
    res.json({ message: 'Solicitud creada con éxito', data: nuevaSolicitud });
  } catch (error) {
    console.error("Error en crearSolicitud:", error);
    httpError(res, error);
  }
};

// Obtener solicitudes por conductor (pendientes)
const getSolicitudesPorConductor = async (req, res) => {
  try {
    const conductorId = req.params.conductorId;

    const solicitudes = await SolicitudTransporte.find({ 
      conductorId, 
      estado: 'pendiente' 
    }).populate('clienteId', 'nombre email telefono tokenFCM');

    res.json({ data: solicitudes });
  } catch (error) {
    console.error("Error en getSolicitudesPorConductor:", error);
    httpError(res, error);
  }
};

// Cambiar estado de una solicitud (aceptada/rechazada/finalizada)
const actualizarEstadoSolicitud = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!['pendiente', 'aceptada', 'rechazada', 'finalizada'].includes(estado)) {
      return res.status(400).json({ error: 'Estado inválido' });
    }

    const solicitud = await SolicitudTransporte.findByIdAndUpdate(id, { estado }, { new: true });
    res.json({ message: 'Solicitud actualizada', data: solicitud });
  } catch (error) {
    console.error("Error en actualizarEstadoSolicitud:", error);
    httpError(res, error);
  }
};

const existeSolicitudPendiente = async (req, res) => {
  try {
    const { clienteId, conductorId } = req.query;
    if (!clienteId || !conductorId) {
      return res.status(400).json({ error: 'Faltan clienteId o conductorId' });
    }

    const existe = await SolicitudTransporte.exists({
      clienteId,
      conductorId,
      estado: 'pendiente',
    });

    res.json({ existe: !!existe });
  } catch (error) {
    console.error("Error en existeSolicitudPendiente:", error);
    httpError(res, error);
  }
};


module.exports = {
  crearSolicitud,
  getSolicitudesPorConductor,
  actualizarEstadoSolicitud,
  existeSolicitudPendiente
};
