const Admin = require('../models/admin');
const bcrypt = require('bcrypt');
const { httpError } = require('../helpers/handleError');

// Crear un administrador
const createAdmin = async (req, res) => {
  try {
    const { nombre, email, username, password } = req.body;

    // Verificar si el email ya existe
    const adminPorEmail = await Admin.findOne({ email });
    if (adminPorEmail) {
      return res.status(400).json({ error: 'Ya existe un administrador con ese email' });
    }

    // Verificar si el username ya existe
    const adminPorUsername = await Admin.findOne({ username });
    if (adminPorUsername) {
      return res.status(400).json({ error: 'Ya existe un administrador con ese username' });
    }

    // Hashear la contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear el nuevo administrador
    const nuevoAdmin = new Admin({
      nombre,
      email,
      username,
      password: hashedPassword,
      tokenFCM: ""
    });

    const adminGuardado = await nuevoAdmin.save();

    res.status(201).json({
      message: 'Administrador creado exitosamente',
      data: {
        id: adminGuardado._id,
        nombre: adminGuardado.nombre,
        email: adminGuardado.email,
        username: adminGuardado.username,
        tokenFCM: adminGuardado.tokenFCM
      },
    });
  } catch (e) {
    console.error("Error en createAdmin:", e);
    httpError(res, e);
  }
};

// obtener un admin por su id
const getAdminById = async (req, res) => {
  try {
    const { id } = req.params;
    const admin = await Admin.findById(id);

    if (!admin) return res.status(404).json({ error: 'Administrador no encontrado' });

    res.json({ data: admin });
  } catch (e) {
    console.error("Error en getAdminById:", e);
    httpError(res, e);
  }
};

const getAllAdmins = async (req, res) => {
  try {
    const admins = await Admin.find();
    res.json({ data: admins });
  } catch (e) {
    console.error("Error en getAllAdmins:", e);
    httpError(res, e);
  }
};

// Enviar notificación push a un administrador
const sendPushNotificationToAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const { titulo, cuerpo } = req.body;

    const administrador = await Admin.findById(id);
    if (!administrador || !administrador.tokenFCM) {
      return res.status(404).json({ error: "Administrador no encontrado o sin token FCM" });
    }

    await admin.messaging().send({
      token: administrador.tokenFCM,
      notification: { title: titulo, body: cuerpo }
    });

    res.json({ message: "Notificación enviada correctamente al administrador" });
  } catch (e) {
    console.error("Error enviando notificación al administrador:", e);
    res.status(500).json({ error: "Error enviando notificación" });
  }
};

// Actualizar el tokenFCM de un administrador
const updateAdminFCMToken = async (req, res) => {
  try {
    const { id } = req.params;
    const { tokenFCM } = req.body;

    if (!tokenFCM) {
      return res.status(400).json({ error: 'El tokenFCM es requerido' });
    }

    const updatedAdmin = await Admin.findByIdAndUpdate(
      id, 
      { tokenFCM }, 
      { new: true }
    );

    if (!updatedAdmin) {
      return res.status(404).json({ error: 'Administrador no encontrado' });
    }

    console.log(`Token FCM actualizado para Administrador (ID: ${id}): ${tokenFCM}`);

    res.json({ message: 'Token FCM actualizado correctamente', data: updatedAdmin });
  } catch (e) {
    console.error("Error en updateAdminFCMToken:", e);
    res.status(500).json({ error: "Error actualizando el token FCM del administrador" });
  }
};

const clearAdminFCMToken = async (req, res) => {
  try {
    const { id } = req.params;

    const updatedAdmin = await Admin.findByIdAndUpdate(id, { tokenFCM: null }, { new: true });

    if (!updatedAdmin) {
      return res.status(404).json({ error: 'Administrador no encontrado' });
    }

    res.json({ message: 'Token FCM del administrador eliminado correctamente', data: updatedAdmin });
  } catch (e) {
    console.error("Error en clearAdminFCMToken:", e);
    httpError(res, e);
  }
};

module.exports = {
  createAdmin,
  getAdminById,
  getAllAdmins,
  sendPushNotificationToAdmin,
  updateAdminFCMToken,
  clearAdminFCMToken
};
