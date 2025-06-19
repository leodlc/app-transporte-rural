const Conductor = require('../models/conductor');
const Ubicacion = require('../models/ubicacion');
const { firestore } = require('../../config/firebase');

module.exports = (socket, io) => {
  socket.on('ubicacion:actualizar', async (data) => {
    try {
      const { conductorId, lat, lng } = data;

      if (!conductorId || typeof lat !== 'number' || typeof lng !== 'number') {
        console.log('Datos inválidos:', data);
        return;
      }

      const conductor = await Conductor.findById(conductorId);
      if (!conductor) {
        console.log('Conductor no encontrado');
        return;
      }

      // Activar ubicación si está desactivada
      if (!conductor.ubicacionActiva) {
        conductor.ubicacionActiva = true;
        console.log(`Activando ubicación para ${conductor.nombre}`);
      }

      // MongoDB: crear o actualizar ubicación
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

      await conductor.save();

      // Firestore
      await firestore.collection('conductoresUbicaciones')
        .doc(conductorId.toString())
        .set({
          conductorId: conductorId.toString(),
          nombre: conductor.nombre,
          lat,
          lng,
          ubicacionActiva: true,
          actualizado: new Date().toISOString()
        });

      // Emitir evento global
      const payload = {
        conductorId: conductorId.toString(),
        nombre: conductor.nombre,
        lat,
        lng,
        ubicacionActiva: true
      };

      io.emit('ubicacion-conductor-actualizada', payload);
      console.log('WebSocket emitido:', payload);

    } catch (err) {
      console.error('Error en conductor.socket.js:', err);
    }
  });


    // Evento para desactivar ubicación y eliminarla de MongoDB + Firestore
    socket.on('ubicacion:desactivar', async (data) => {
    try {
        const { conductorId } = data;

        if (!conductorId) {
        console.log('conductorId faltante');
        return;
        }

        const conductor = await Conductor.findById(conductorId);
        if (!conductor) {
        console.log('Conductor no encontrado');
        return;
        }

        // Eliminar ubicación en MongoDB si existe
        if (conductor.ubicacion) {
        await Ubicacion.findByIdAndDelete(conductor.ubicacion);
        conductor.ubicacion = null;
        }

        // Desactivar ubicación
        conductor.ubicacionActiva = false;
        await conductor.save();

        // Eliminar documento de Firestore
        await firestore.collection('conductoresUbicaciones')
        .doc(conductorId.toString())
        .delete();

        // Emitir evento global
        io.emit('ubicacion-conductor-desactivada', {
        conductorId: conductor._id.toString(),
        nombre: conductor.nombre,
        ubicacionActiva: false
        });

        console.log(`Ubicación desactivada y eliminada para ${conductor.nombre}`);
    } catch (err) {
        console.error('Error al desactivar ubicación:', err);
    }
    });

};
