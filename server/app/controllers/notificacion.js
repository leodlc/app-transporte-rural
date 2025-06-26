// controllers/notificacion.js
const Cliente = require('../models/cliente');
const Conductor = require('../models/conductor');
const Admin = require('../models/admin');
const Notificacion = require('../models/notificacion');
const { admin } = require('../../config/firebase');

const actualizarTokenFCM = async (req, res) => {
  const { usuarioId, tokenFCM, rol } = req.body;

  if (!usuarioId || !tokenFCM || !rol) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  try {
    const modelo = rol === 'cliente' ? Cliente :
                   rol === 'conductor' ? Conductor :
                   rol === 'admin' ? Admin : null;

    if (!modelo) return res.status(400).json({ error: 'Rol inválido' });

    const usuario = await modelo.findById(usuarioId);
    if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

    // Asegurarse que tokenFCM es un array
    if (!Array.isArray(usuario.tokenFCM)) {
      usuario.tokenFCM = [];
    }

    // Agregar solo si no existe
    if (!usuario.tokenFCM.includes(tokenFCM)) {
      usuario.tokenFCM.push(tokenFCM);
      await usuario.save();
    }

    res.json({ message: 'Token FCM actualizado correctamente' });
  } catch (error) {
    console.error('Error actualizando token FCM:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};


const enviarNotificacion = async (req, res) => {
  const { usuarioId, rol, emisorId, rolEmisor, titulo, cuerpo } = req.body;

  if (!usuarioId || !rol || !emisorId || !rolEmisor || !titulo || !cuerpo) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  try {
    const modelo = rol === 'cliente' ? Cliente :
                   rol === 'conductor' ? Conductor :
                   rol === 'admin' ? Admin : null;

    if (!modelo) return res.status(400).json({ error: 'Rol receptor inválido' });

    const usuario = await modelo.findById(usuarioId);
    if (!usuario || !usuario.tokenFCM || usuario.tokenFCM.length === 0) {
      return res.status(404).json({ error: 'Usuario sin tokens disponibles' });
    }

    const mensaje = {
      notification: {
        title: titulo,
        body: cuerpo
      },
      tokens: usuario.tokenFCM
    };

    const response = await admin.messaging().sendEachForMulticast(mensaje);

    // Guardar con emisor
    await Notificacion.create({ usuarioId, rol, emisorId, rolEmisor, titulo, cuerpo });

    res.json({
      message: 'Notificación enviada',
      successCount: response.successCount,
      failureCount: response.failureCount
    });
  } catch (error) {
    console.error('Error enviando notificación:', error);
    res.status(500).json({ error: 'Error enviando notificación' });
  }
};


module.exports = {
  actualizarTokenFCM,
  enviarNotificacion
};
