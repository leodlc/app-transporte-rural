const { httpError } = require('../helpers/handleError');
const Cliente = require('../models/cliente'); // Importamos el modelo
const bcrypt = require('bcrypt');


// Obtener todos los clientes
const getAllClients = async (req, res) => {
  try {
    const clients = await Cliente.find();
    res.json({ data: clients });
  } catch (e) {
    console.error("Error in getAllClients:", e);
    httpError(res, e);
  }
};



const getClientById = async (req, res) => {
  try {
    const { id } = req.params;

    let client = null;

    try {
      client = await Cliente.findById(id)
        .populate({
          path: 'direccion',
          populate: { path: 'ubicacion' }
        })
        .exec();
    } catch (populateError) {
      console.warn("Populate falló, retornando cliente sin populate:", populateError.message);
      client = await Cliente.findById(id); // fallback sin populate
    }

    if (!client) return res.status(404).json({ error: 'Cliente no encontrado' });

    res.json({ data: client });
  } catch (e) {
    console.error("Error in getClientById:", e);
    res.status(500).json({ error: 'Algo salió mal', details: e.message });
  }
};





// Obtener un cliente por su nombre
const getClientByName = async (req, res) => {
  try {
    let nombreCliente = decodeURIComponent(req.params.nombreCliente);
    
    // Eliminar espacios en blanco del nombre
    nombreCliente = nombreCliente.replace(/\s+/g, '').toLowerCase();

    // Buscar cliente ignorando espacios y mayúsculas/minúsculas
    const client = await Cliente.findOne({
      $expr: {
        $eq: [
          { $replaceAll: { input: { $toLower: "$nombre" }, find: " ", replacement: "" } },
          nombreCliente
        ]
      }
    });

    if (!client) return res.status(404).json({ error: 'Cliente no encontrado' });

    res.json({ data: client });
  } catch (e) {
    console.error("Error in getClientByName:", e);
    httpError(res, e);
  }
};


// Crear un cliente con contraseña encriptada
const createClient = async (req, res) => {
  try {
    const { nombre, username,direccion, telefono, email, password } = req.body;

    // Verificar si el email ya existe
    const existingClient = await Cliente.findOne({ email });
    if (existingClient) {
      return res.status(400).json({ error: 'El email ya está registrado' });
    }

    // Encriptar la contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Validar si `direccion` es un ObjectId válido, si no, dejarlo como `null`
    let direccionValida = null;
    if (direccion && mongoose.Types.ObjectId.isValid(direccion)) {
      direccionValida = direccion;
    }

    // Crear el cliente con la contraseña encriptada
    const nuevoCliente = new Cliente({
      nombre,
      username,
      telefono,
      email,
      password: hashedPassword, //  Guardar la contraseña encriptada
      direccion: direccionValida //  Asignar `null` si `direccion` es inválida
    });

    const clienteGuardado = await nuevoCliente.save();

    res.status(201).json({
      message: 'Cliente creado exitosamente',
      data: clienteGuardado
    });
  } catch (e) {
    console.error("Error in createClient:", e);
    httpError(res, e);
  }
};


// Actualizar un cliente
const updateClient = async (req, res) => {
  try {
    const { id } = req.params;
    const updatedClient = await Cliente.findByIdAndUpdate(id, req.body, { new: true });

    if (!updatedClient) return res.status(404).json({ error: 'Cliente no encontrado' });

    res.json({ message: 'Cliente actualizado correctamente', data: updatedClient });
  } catch (e) {
    console.error("Error in updateClient:", e);
    httpError(res, e);
  }
};

// Eliminar un cliente
const deleteClient = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await Cliente.findByIdAndDelete(id);

    if (!result) return res.status(404).json({ error: 'Cliente no encontrado' });

    res.json({ message: 'Cliente eliminado correctamente' });
  } catch (e) {
    console.error("Error in deleteClient:", e);
    httpError(res, e);
  }
};

// Actualizar el tokenFCM de un cliente
const updateClientFCMToken = async (req, res) => {
  try {
    const { id } = req.params;
    const { tokenFCM } = req.body;

    if (!tokenFCM) {
      return res.status(400).json({ error: 'El tokenFCM es requerido' });
    }

    const updatedClient = await Cliente.findByIdAndUpdate(
      id, 
      { tokenFCM }, 
      { new: true }
    );

    if (!updatedClient) {
      return res.status(404).json({ error: 'Cliente no encontrado' });
    }

    console.log(`Token FCM actualizado para Cliente (ID: ${id}): ${tokenFCM}`);

    res.json({ message: 'Token FCM actualizado correctamente', data: updatedClient });
  } catch (e) {
    console.error("Error en updateClientFCMToken:", e);
    httpError(res, e);
  }
  
};

const sendPushNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const { titulo, cuerpo } = req.body;

    const cliente = await Cliente.findById(id);
    if (!cliente || !cliente.tokenFCM) {
      return res.status(404).json({ error: "Cliente no encontrado o sin token FCM" });
    }

    await admin.messaging().send({
      token: cliente.tokenFCM,
      notification: { title: titulo, body: cuerpo }
    });

    res.json({ message: "Notificación enviada correctamente" });
  } catch (e) {
    console.error("Error enviando notificación:", e);
    res.status(500).json({ error: "Error enviando notificación" });
  }
};

module.exports = {
  getAllClients,
  getClientByName,
  getClientById,
  createClient,
  updateClient,
  deleteClient,
  updateClientFCMToken,
  sendPushNotification
};