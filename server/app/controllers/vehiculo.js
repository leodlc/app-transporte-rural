const { httpError } = require('../helpers/handleError');
const Vehiculo = require('../models/vehiculo'); // Importamos el modelo

// Obtener todos los vehículos
const getAllVehiculos = async (req, res) => {
  try {
    const vehiculos = await Vehiculo.find();
    res.json({ data: vehiculos });
  } catch (e) {
    console.error("Error in getAllVehiculos:", e);
    httpError(res, e);
  }
};

// Obtener un vehículo por su placa
const getVehiculoByPlaca = async (req, res) => {
  try {
    const { placa } = req.params;
    const vehiculo = await Vehiculo.findOne({ placa: new RegExp(`^${placa}$`, 'i') });

    if (!vehiculo) return res.status(404).json({ error: 'Vehículo no encontrado' });

    res.json({ data: vehiculo });
  } catch (e) {
    console.error("Error in getVehiculoByPlaca:", e);
    httpError(res, e);
  }
};

// Crear un vehículo
const createVehiculo = async (req, res) => {
  try {
    const nuevoVehiculo = new Vehiculo(req.body);
    const vehiculoGuardado = await nuevoVehiculo.save();

    res.status(201).json({
      message: 'Vehículo creado exitosamente',
      data: vehiculoGuardado
    });
  } catch (e) {
    console.error("Error in createVehiculo:", e);
    httpError(res, e);
  }
};

// Actualizar un vehículo
const updateVehiculo = async (req, res) => {
  try {
    const { id } = req.params;
    const updatedVehiculo = await Vehiculo.findByIdAndUpdate(id, req.body, { new: true });

    if (!updatedVehiculo) return res.status(404).json({ error: 'Vehículo no encontrado' });

    res.json({ message: 'Vehículo actualizado correctamente', data: updatedVehiculo });
  } catch (e) {
    console.error("Error in updateVehiculo:", e);
    httpError(res, e);
  }
};

// Eliminar un vehículo
const deleteVehiculo = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await Vehiculo.findByIdAndDelete(id);

    if (!result) return res.status(404).json({ error: 'Vehículo no encontrado' });

    res.json({ message: 'Vehículo eliminado correctamente' });
  } catch (e) {
    console.error("Error in deleteVehiculo:", e);
    httpError(res, e);
  }
};

module.exports = {
  getAllVehiculos,
  getVehiculoByPlaca,
  createVehiculo,
  updateVehiculo,
  deleteVehiculo
};
