const Cliente = require('../models/cliente');
const Direccion = require('../models/direccion');
const Ubicacion = require('../models/ubicacion');

module.exports = (socket, io) => {

  socket.on('cliente:ubicacion-actualizar', async (data) => {
    try {
      const { clienteId, lat, lng } = data;

      if (!clienteId || typeof lat !== 'number' || typeof lng !== 'number') {
        console.log('Datos inválidos:', data);
        return;
      }

      const cliente = await Cliente.findById(clienteId).populate('direccion');
      if (!cliente) {
        console.log('Cliente no encontrado');
        return;
      }

      let ubicacion;

      if (cliente.direccion && cliente.direccion.ubicacion) {
        // Actualizar ubicación existente
        ubicacion = await Ubicacion.findByIdAndUpdate(
          cliente.direccion.ubicacion,
          { lat, lng },
          { new: true }
        );
      } else {
        // Crear nueva ubicación y asociarla
        ubicacion = new Ubicacion({ lat, lng });
        await ubicacion.save();

        let direccion = cliente.direccion;
        if (!direccion) {
          direccion = new Direccion({ ubicacion: ubicacion._id });
          await direccion.save();
          cliente.direccion = direccion._id;
        } else {
          direccion.ubicacion = ubicacion._id;
          await direccion.save();
        }
      }

      // Activar ubicación
      if (!cliente.ubicacionActiva) {
        cliente.ubicacionActiva = true;
        console.log(`Ubicación activada para cliente ${cliente.nombre}`);
      }

      await cliente.save();

      const payload = {
        clienteId: clienteId.toString(),
        nombre: cliente.nombre,
        lat,
        lng,
        ubicacionActiva: true
      };

      io.emit('cliente-ubicacion-actualizada', payload);
      console.log('Ubicación cliente actualizada:', payload);

    } catch (err) {
      console.error('Error en cliente.socket.js (actualizar):', err);
    }
  });

  socket.on('cliente:ubicacion-desactivar', async (data) => {
    try {
      const { clienteId } = data;

      if (!clienteId) {
        console.log('clienteId faltante');
        return;
      }

      const cliente = await Cliente.findById(clienteId).populate('direccion');
      if (!cliente) {
        console.log('Cliente no encontrado');
        return;
      }

      if (cliente.direccion && cliente.direccion.ubicacion) {
        await Ubicacion.findByIdAndDelete(cliente.direccion.ubicacion);
        await Direccion.findByIdAndDelete(cliente.direccion._id);
        cliente.direccion = null;
      }

      cliente.ubicacionActiva = false;
      await cliente.save();

      io.emit('cliente-ubicacion-desactivada', {
        clienteId: cliente._id.toString(),
        nombre: cliente.nombre,
        ubicacionActiva: false
      });

      console.log(`Ubicación desactivada para cliente ${cliente.nombre}`);
    } catch (err) {
      console.error('Error en cliente.socket.js (desactivar):', err);
    }
  });
};
