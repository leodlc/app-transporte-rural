const Frase = require('../models/frase');
const { httpError } = require('../helpers/handleError');

// Crear una nueva frase
const createFrase = async (req, res) => {
  try {
    const { frase } = req.body;

    if (!frase) {
      return res.status(400).json({ error: 'El campo "frase" es requerido' });
    }

    const nuevaFrase = new Frase({ frase });
    const fraseGuardada = await nuevaFrase.save();

    res.status(201).json({
      message: 'Frase creada exitosamente',
      data: fraseGuardada,
    });
  } catch (e) {
    console.error("Error en createFrase:", e);
    httpError(res, e);
  }
};

// Obtener una frase aleatoria
const getFraseAleatoria = async (req, res) => {
  try {
    const total = await Frase.countDocuments();
    if (total === 0) {
      return res.status(404).json({ error: 'No hay frases disponibles' });
    }

    const randomIndex = Math.floor(Math.random() * total);
    const frase = await Frase.findOne().skip(randomIndex);

    res.json({ data: frase });
  } catch (e) {
    console.error("Error en getFraseAleatoria:", e);
    httpError(res, e);
  }
};

// Obtener todas las frases
const getAllFrases = async (req, res) => {
  try {
    const frases = await Frase.find().sort({ createdAt: -1 });
    res.json({ data: frases });
  } catch (e) {
    console.error("Error en getAllFrases:", e);
    httpError(res, e);
  }
};

// Eliminar una frase por ID
const deleteFraseById = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Frase.findByIdAndDelete(id);

    if (!deleted) {
      return res.status(404).json({ error: 'Frase no encontrada' });
    }

    res.json({ message: 'Frase eliminada correctamente' });
  } catch (e) {
    console.error("Error en deleteFraseById:", e);
    httpError(res, e);
  }
};

module.exports = {
  createFrase,
  getFraseAleatoria,
  getAllFrases,
  deleteFraseById,
};
