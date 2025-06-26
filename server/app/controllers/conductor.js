const {httpError} = require('../helpers/handleError');
const Conductor = require('../models/conductor');
const Ubicacion = require('../models/ubicacion');
const bcrypt = require('bcrypt');
const { sendVerificationEmail } = require('../helpers/mailer');
const { v4: uuidv4 } = require('uuid');
const { getSocket } = require('../../config/socket');
const { firestore } = require('../../config/firebase'); // Importa Firestore si lo necesitas


// Obtener todos los conductores
const getAllDrivers = async (req, res) => {
    try {
        const drivers = await Conductor.find().populate('vehiculo').populate('cooperativa');
        res.json({data: drivers});
    } catch (e) {
        console.error("Error in getAllDrivers:", e);
        httpError(res, e);
    }
};

// Obtener un conductor por su id
const getDriverById = async (req, res) => {
    try {
        const {id} = req.params;
        const driver = await Conductor.findById(id).populate('vehiculo').populate('cooperativa');

        if (!driver) return res.status(404).json({error: 'Conductor no encontrado'});

        res.json({data: driver});
    } catch (e) {
        console.error("Error in getDriverById:", e);
        httpError(res, e);
    }
};
// Obtener un conductor por su nombre
const getDriverByName = async (req, res) => {
    try {
        let nombreConductor = decodeURIComponent(req.params.nombreConductor);

        // Eliminar espacios y tildes del nombre
        const normalizeText = (text) => {
            return text
                .normalize("NFD") // Descompone caracteres en base + tilde
                .replace(/[\u0300-\u036f]/g, '') // Elimina los diacríticos (tildes)
                .replace(/\s+/g, '') // Elimina espacios
                .toLowerCase();
        };

        nombreConductor = normalizeText(nombreConductor);

        // Buscar conductor ignorando espacios y tildes
        const driver = await Conductor.findOne({
            $expr: {
                $eq: [
                    { $replaceAll: { input: { $toLower: "$nombre" }, find: " ", replacement: "" } },
                    nombreConductor
                ]
            }
        });

        if (!driver) return res.status(404).json({ error: 'Conductor no encontrado' });

        res.json({ data: driver });
    } catch (e) {
        console.error("Error in getDriverByName:", e);
        httpError(res, e);
    }
};


// Crear un conductor
const createDriver = async (req, res) => {
  try {
    const { nombre, username, email, telefono, password, tokenFCM, rol, cooperativa, ubicacionActiva } = req.body;

    const existingDriver = await Conductor.findOne({ email });
    if (existingDriver) {
      return res.status(400).json({ error: 'El email ya está registrado' });
    }

    const verificationCode = uuidv4().replace(/-/g, '').slice(0, 6).toUpperCase();

    try {
      await sendVerificationEmail(email, verificationCode);
    } catch (emailError) {
      console.error("Error al enviar el email:", emailError);
      return res.status(500).json({ error: 'Error al enviar el correo de verificación' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const nuevoConductor = new Conductor({
      nombre,
      username,
      cooperativa,
      email,
      telefono,
      password: hashedPassword,
      tokenFCM,
      activo: true, // ← importante
      rol,
      emailVerificado: false,
      verificationCode,
      ubicacionActiva: false
    });

    const conductorGuardado = await nuevoConductor.save();

    res.status(201).json({
      message: 'Conductor creado exitosamente. Se envió un código de verificación al correo.',
      data: conductorGuardado
    });
  } catch (e) {
    console.error("Error en createDriver:", e);
    httpError(res, e);
  }
};


// Actualizar un conductor
const updateDriver = async (req, res) => {
    try{
        const {id} = req.params;
        const updatedDriver = await Conductor.findByIdAndUpdate(id, req.body, {new: true});

        if (!updatedDriver) return res.status(404).json({error: 'Conductor no encontrado'});
        res.json({message: 'Conductor actualizado correctamente', data: updatedDriver});
    }catch(e){
        console.error("Error in updateDriver:", e);
        httpError(res, e);
    }
};

// Eliminar un conductor
const deleteDriver = async (req, res) => {
    try{
        const {id} = req.params;
        const result = await Conductor.findByIdAndDelete(id);

        if (!result) return res.status(404).json({error: 'Conductor no encontrado'});
        res.json({message: 'Conductor eliminado correctamente'});
    }catch(e){
        console.error("Error in deleteDriver:", e);
        httpError(res, e);
    }
};



  // Actualizar el tokenFCM de un conductor
const updateDriverFCMToken = async (req, res) => {
    try {
      const { id } = req.params;
      const { tokenFCM } = req.body;
  
      if (!tokenFCM) {
        return res.status(400).json({ error: 'El tokenFCM es requerido' });
      }
  
      const updatedDriver = await Conductor.findByIdAndUpdate(
        id, 
        { tokenFCM }, 
        { new: true }
      );
  
      if (!updatedDriver) {
        return res.status(404).json({ error: 'Conductor no encontrado' });
      }
  
      console.log(`Token FCM actualizado para Conductor (ID: ${id}): ${tokenFCM}`);
  
      res.json({ message: 'Token FCM actualizado correctamente', data: updatedDriver });
    } catch (e) {
      console.error("Error en updateDriverFCMToken:", e);
      httpError(res, e);
    }
  };


const actualizarUbicacionActiva = async (req, res) => {
  try {
    const { id } = req.params;
    const { activa, lat, lng } = req.body;

    if (typeof activa === 'undefined' || typeof lat !== 'number' || typeof lng !== 'number') {
      return res.status(400).json({ error: 'Parámetros incompletos o inválidos (activa, lat, lng)' });
    }

    const conductor = await Conductor.findById(id);
    if (!conductor) {
      return res.status(404).json({ error: 'Conductor no encontrado' });
    }

    // Actualizar o crear ubicación en MongoDB
    let ubicacion;
    if (conductor.ubicacion) {
      ubicacion = await Ubicacion.findByIdAndUpdate(
        conductor.ubicacion,
        { lat, lng },
        { new: true }
      );
    } else {
      ubicacion = new Ubicacion({ lat, lng });
      await ubicacion.save();
      conductor.ubicacion = ubicacion._id;
    }

    // Actualizar estado
    conductor.ubicacionActiva = activa;
    await conductor.save();

    // Emitir por WebSocket
    const payload = {
      conductorId: conductor._id.toString(),
      nombre: conductor.nombre,
      lat,
      lng,
      ubicacionActiva: activa
    };
    getSocket().emit('ubicacion-conductor-actualizada', payload);
    console.log('WebSocket emitido: ubicacion-conductor-actualizada', payload);

    // Guardar en Firestore
    await firestore.collection('conductoresUbicaciones')
      .doc(conductor._id.toString())
      .set({
        ...payload,
        actualizado: new Date().toISOString()
      });
    
    console.log(`Firestore actualizado: conductoresUbicaciones/${conductor._id.toString()}`);
    res.json({
      message: 'Ubicación y estado actualizados correctamente',
      data: payload
    });

  } catch (error) {
    console.error('Error en actualizarUbicacionActiva:', error);
    httpError(res, error);
  }
};
const getActiveDrivers = async (req, res) => {
  try {
    const conductoresActivos = await Conductor.find({ ubicacionActiva: true });
    res.status(200).json(conductoresActivos);
  } catch (e) {
    console.error("Error en getActiveDrivers:", e);
    httpError(res, e);
  }
};
const clearDriverFCMToken = async (req, res) => {
  try {
    const { id } = req.params;

    const updatedDriver = await Conductor.findByIdAndUpdate(id, { tokenFCM: null }, { new: true });

    if (!updatedDriver) {
      return res.status(404).json({ error: 'Conductor no encontrado' });
    }

    res.json({ message: 'Token FCM eliminado correctamente', data: updatedDriver });
  } catch (e) {
    console.error("Error en clearDriverFCMToken:", e);
    httpError(res, e);
  }
};


module.exports = {
    getAllDrivers,
    getDriverByName,
    getDriverById,
    createDriver,
    updateDriver,
    deleteDriver,
    updateDriverFCMToken,
    actualizarUbicacionActiva,
    getActiveDrivers,
    clearDriverFCMToken
};
