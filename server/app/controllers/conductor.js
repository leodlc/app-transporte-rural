const {httpError} = require('../helpers/handleError');
const Conductor = require('../models/conductor');
const Ubicacion = require('../models/ubicacion');
const bcrypt = require('bcrypt');
const { sendVerificationEmail } = require('../helpers/mailer');
const { v4: uuidv4 } = require('uuid');
const { getSocket } = require('../../config/socket');
const { firestore } = require('../../config/firebase'); // Importa Firestore si lo necesitas
//const admin = require('firebase-admin');
// Memoria temporal para evitar actualizar MongoDB en cada cambio de ubicación
//const ubicacionesTemporales = new Map();

// Distancia en metros para considerar que el conductor está "cerca"
//const DISTANCIA_MINIMA = 500; // 500 metros

// Función para calcular la distancia entre dos coordenadas (Haversine formula)
/*
const calcularDistancia = (lat1, lon1, lat2, lon2) => {
  const R = 6371000; // Radio de la Tierra en metros
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};*/

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

// Función para actualizar la ubicación en Firestore en tiempo real
/*const updateDriverLocationRealtime = async (req, res) => {
    try {
        const { id } = req.params;
        const { lat, lng } = req.body;

        // Buscar el conductor
        const conductor = await Conductor.findById(id);
        if (!conductor) return res.status(404).json({ error: 'Conductor no encontrado' });

        // Actualizar Firestore en tiempo real
        await admin.firestore().collection('ubicaciones').doc(id).set({
            conductorId: id,
            lat,
            lng,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // Guardar ubicación en memoria para actualizar MongoDB después de un tiempo
        ubicacionesTemporales.set(id, { lat, lng, lastUpdated: Date.now() });

        res.json({ message: 'Ubicación del conductor actualizada en Firestore' });
    } catch (e) {
        console.error("Error in updateDriverLocationRealtime:", e);
        httpError(res, e);
    }
};
*/

// Función para actualizar MongoDB cada 30 segundos
/*const updateDriverLocationMongoDB = async () => {
    const now = Date.now();

    for (const [id, data] of ubicacionesTemporales) {
        if (now - data.lastUpdated >= 30000) { // 30 segundos
            try {
                const conductor = await Conductor.findById(id);
                if (!conductor) continue;

                // Si el conductor ya tiene una ubicación en MongoDB, actualizarla
                if (conductor.ubicacion) {
                    await Ubicacion.findByIdAndUpdate(conductor.ubicacion, { lat: data.lat, lng: data.lng });
                } else {
                    // Si no tiene, crear una nueva ubicación
                    const nuevaUbicacion = new Ubicacion({ lat: data.lat, lng: data.lng });
                    const ubicacionGuardada = await nuevaUbicacion.save();

                    // Asociar la nueva ubicación al conductor
                    conductor.ubicacion = ubicacionGuardada._id;
                    await conductor.save();
                }

                console.log(`Ubicación del conductor ${id} actualizada en MongoDB`);
                ubicacionesTemporales.delete(id);
            } catch (e) {
                console.error(`Error actualizando ubicación en MongoDB para el conductor ${id}:`, e);
            }
        }
    }
};
*/

/*
// Ejecutar la actualización de MongoDB cada 30 segundos
setInterval(updateDriverLocationMongoDB, 30000);


// Función para verificar si el conductor está cerca del destino
const verificarConductorCerca = async (conductorId) => {
    try {
      const conductor = await Conductor.findById(conductorId).populate('ubicacion');
      if (!conductor || !conductor.ubicacion) return;
  
      // Obtener el pedido asignado al conductor
      const pedido = await Pedido.findOne({ conductor: conductorId, estado: 'en camino' }).populate('destino cliente');
      if (!pedido || !pedido.destino) return;
  
      const destino = await Ubicacion.findById(pedido.destino.ubicacion);
      if (!destino) return;
  
      // Calcular la distancia entre la ubicación del conductor y el destino
      const distancia = calcularDistancia(
        conductor.ubicacion.lat,
        conductor.ubicacion.lng,
        destino.lat,
        destino.lng
      );
  
      console.log(`🚗 Conductor ${conductorId} -> Distancia al destino: ${distancia.toFixed(2)}m`);
  
      if (distancia < DISTANCIA_MINIMA) {
        sendPushNotification(
          pedido.cliente.tokenFCM,
          "Tu pedido está cerca",
          "El conductor está a menos de 500 metros de tu ubicación.",
          pedido.cliente._id.toString(),
          "Cliente"
        );
      }
    } catch (e) {
      console.error(`❌ Error en verificarConductorCerca para conductor ${conductorId}:`, e);
    }
  };
  
  
  // Verificar ubicación de los conductores cada 10 segundos
  setInterval(async () => {
    const conductores = await Conductor.find({ activo: true });
    conductores.forEach(conductor => verificarConductorCerca(conductor._id));
  }, 10000);
*/

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

/* 
// Obtener conductores disponibles (con vehículo y sin pedidos activos)
const getAvailableDrivers = async (req, res) => {
    try {
        const conductoresDisponibles = await Conductor.find({ 
            activo: true, // Solo conductores disponibles
            vehiculo: { $ne: null } // Que tengan vehículo asignado
        }).populate('vehiculo', 'marca modelo placa'); // Mostrar datos del vehículo

        if (!conductoresDisponibles.length) {
            return res.status(404).json({ error: 'No hay conductores disponibles' });
        }

        res.json({ data: conductoresDisponibles });
    } catch (e) {
        console.error("Error en getAvailableDrivers:", e);
        httpError(res, e);
    }
};
*/
/*
// Función para asignar un pedido a un conductor
const assignOrderToDriver = async (req, res) => {
    try {
        const { pedidoId, conductorId } = req.body;

        // Verificar si el pedido existe
        const pedido = await Pedido.findById(pedidoId);
        if (!pedido) return res.status(404).json({ error: 'Pedido no encontrado' });

        // Verificar si el conductor existe y está disponible
        const conductor = await Conductor.findById(conductorId);
        if (!conductor || !conductor.activo || !conductor.vehiculo) {
            return res.status(400).json({ error: 'El conductor no está disponible o no tiene vehículo' });
        }

        // Asignar el pedido al conductor y cambiar su estado a inactivo
        pedido.conductor = conductorId;
        pedido.estado = 'asignado';
        await pedido.save();

        conductor.activo = false; // El conductor ahora tiene un pedido asignado
        await conductor.save();

        console.log(`🚗 Pedido ${pedidoId} asignado al conductor ${conductorId}`);

        res.json({ message: 'Pedido asignado exitosamente', data: pedido });
    } catch (e) {
        console.error("Error en assignOrderToDriver:", e);
        httpError(res, e);
    }
};

// Función para cambiar el estado del conductor cuando el pedido es entregado o cancelado
const updateDriverStatusOnOrderCompletion = async (pedidoId) => {
    try {
        const pedido = await Pedido.findById(pedidoId);
        if (!pedido || !pedido.conductor) return;

        if (pedido.estado === 'entregado' || pedido.estado === 'cancelado') {
            const conductor = await Conductor.findById(pedido.conductor);
            if (conductor) {
                conductor.activo = true; // El conductor vuelve a estar disponible
                await conductor.save();
                console.log(`Conductor ${conductor._id} está disponible nuevamente`);
            }
        }
    } catch (e) {
        console.error("Error en updateDriverStatusOnOrderCompletion:", e);
    }
};

const sendPushNotificationToConductor = async (req, res) => {
    try {
      const { id } = req.params;
      const { titulo, cuerpo } = req.body;
  
      const conductor = await Conductor.findById(id);
      if (!conductor || !conductor.tokenFCM) {
        return res.status(404).json({ error: "Conductor no encontrado o sin token FCM" });
      }
  
      await admin.messaging().send({
        token: conductor.tokenFCM,
        notification: { title: titulo, body: cuerpo }
      });
  
      res.json({ message: "Notificación enviada correctamente al conductor" });
    } catch (e) {
      console.error("Error enviando notificación al conductor:", e);
      res.status(500).json({ error: "Error enviando notificación" });
    }
  };
*/
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
};
