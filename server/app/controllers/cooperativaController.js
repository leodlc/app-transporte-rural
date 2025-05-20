const Cooperativa = require('../models/cooperativa');
const { httpError } = require('../helpers/handleError');

// Crear una cooperativa
const createCooperativa = async (req, res) => {
  try {
    const { nombre, email, responsable, ubicacion, telefono } = req.body;

    const existeEmail = await Cooperativa.findOne({ email });
    if (existeEmail) {
      return res.status(400).json({ error: 'Ya existe una cooperativa con ese email' });
    }

    const existeResponsable = await Cooperativa.findOne({ responsable });
    if (existeResponsable) {
      return res.status(400).json({ error: 'Ya existe una cooperativa con ese responsable' });
    }

    const nuevaCooperativa = new Cooperativa({
      nombre,
      email,
      responsable,
      ubicacion,
      telefono
    });

    const guardado = await nuevaCooperativa.save();

    res.status(201).json({
      message: 'Cooperativa creada exitosamente',
      data: guardado
    });

  } catch (e) {
    console.error("Error en createCooperativa:", e);
    httpError(res, e);
  }
};

// Obtener cooperativa por ID
const getCooperativaById = async (req, res) => {
  try {
    const { id } = req.params;
    const cooperativa = await Cooperativa.findById(id);

    if (!cooperativa) {
      return res.status(404).json({ error: 'Cooperativa no encontrada' });
    }

    res.json({ data: cooperativa });
  } catch (e) {
    console.error("Error en getCooperativaById:", e);
    httpError(res, e);
  }
};

// Obtener todas las cooperativas
const getAllCooperativas = async (_req, res) => {
  try {
    const cooperativas = await Cooperativa.find();
    res.json({ data: cooperativas });
  } catch (e) {
    console.error("Error en getAllCooperativas:", e);
    httpError(res, e);
  }
};

// Actualizar cooperativa
const updateCooperativa = async (req, res) => {
  try {
    const { id } = req.params;
    const datos = req.body;

    const actualizada = await Cooperativa.findByIdAndUpdate(id, datos, {
      new: true,
      runValidators: true,
    });

    if (!actualizada) {
      return res.status(404).json({ error: 'Cooperativa no encontrada' });
    }

    res.json({
      message: 'Cooperativa actualizada exitosamente',
      data: actualizada
    });
  } catch (e) {
    console.error("Error en updateCooperativa:", e);
    httpError(res, e);
  }
};

// Eliminar cooperativa
const deleteCooperativa = async (req, res) => {
  try {
    const { id } = req.params;

    const eliminada = await Cooperativa.findByIdAndDelete(id);

    if (!eliminada) {
      return res.status(404).json({ error: 'Cooperativa no encontrada' });
    }

    res.json({ message: 'Cooperativa eliminada exitosamente' });
  } catch (e) {
    console.error("Error en deleteCooperativa:", e);
    httpError(res, e);
  }
};

module.exports = {
  createCooperativa,
  getCooperativaById,
  getAllCooperativas,
  updateCooperativa,
  deleteCooperativa
};
