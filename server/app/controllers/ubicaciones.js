const { httpError } = require('../helpers/handleError');
const Ubicacion = require('../models/ubicacion');
const admin = require('firebase-admin'); // Firebase SDK
const Cliente = require('../models/cliente');

// Crear ubicacion para pruebas en postman
const createUbicacion = async (req, res) => {
  try {
    const nuevaUbicacion = new Ubicacion(req.body);
    const ubicacionGuardada = await nuevaUbicacion.save();

    res.status(201).json({
      message: 'Ubicación creada exitosamente',
      data: ubicacionGuardada
    });
  } catch (e) {
    console.error("Error in createUbicacion:", e);
    httpError(res, e);
  }
};

// Obtener la ubicación de un cliente o conductor
const getUbicacionById = async (req, res) => {
  try {
    const { id } = req.params;
    const ubicacion = await Ubicacion.findById(id);

    if (!ubicacion) return res.status(404).json({ error: 'Ubicación no encontrada' });

    res.json({ data: ubicacion });
  } catch (e) {
    console.error("Error in getUbicacionById:", e);
    httpError(res, e);
  }
};

// Actualizar ubicación de un conductor en Firestore para rastreo en tiempo real
const updateUbicacionConductor = async (req, res) => {
  try {
    const { id } = req.params;
    const { lat, lng } = req.body;

    const ubicacionActualizada = await Ubicacion.findByIdAndUpdate(id, { lat, lng }, { new: true });

    if (!ubicacionActualizada) return res.status(404).json({ error: 'Ubicación no encontrada' });

    // Actualizar en Firestore para seguimiento en tiempo real
    await admin.firestore().collection('ubicaciones').doc(id).set({
      lat,
      lng,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: 'Ubicación actualizada en Firestore', data: ubicacionActualizada });
  } catch (e) {
    console.error("Error in updateUbicacionConductor:", e);
    httpError(res, e);
  }
};



module.exports = {
  createUbicacion,
  getUbicacionById,
  updateUbicacionConductor
};
