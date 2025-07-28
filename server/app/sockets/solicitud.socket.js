const SolicitudTransporte = require('../models/solicitudTransporte');
const Cliente = require('../models/cliente');

module.exports = (socket, io) => {

  // 1. Cliente envía solicitud a un conductor
  socket.on('solicitud:crear', async (data) => {
    try {
      const { clienteId, conductorId } = data;
      if (!clienteId || !conductorId) {
        return socket.emit('solicitud:error', 'clienteId y conductorId son requeridos');
      }

      const solicitud = await SolicitudTransporte.create({ clienteId, conductorId });

      const solicitudes = await SolicitudTransporte.find({ 
        conductorId, 
        estado: 'pendiente' 
      }).populate('clienteId', 'nombre email telefono tokenFCM');

      // Notificar al cliente y al conductor (si están conectados)
      socket.emit('solicitud:creada', solicitud);

      console.log(`Solicitud creada por cliente ${clienteId} para conductor ${conductorId}`);
      // Emitir solo al conductor específico (si está conectado)
      io.to(`conductor_${conductorId}`).emit('solicitud:lista', solicitudes);

    } catch (err) {
      console.error('Error en solicitud:crear:', err);
      socket.emit('solicitud:error', 'Error al crear la solicitud');
    }
  });

  // 2. Conductor consulta sus solicitudes pendientes
  socket.on('solicitud:obtener', async (data) => {
    try {
      const { conductorId } = data;
      if (!conductorId) return socket.emit('solicitud:error', 'conductorId requerido');

      const solicitudes = await SolicitudTransporte.find({ 
        conductorId, 
        estado: 'pendiente' 
      }).populate('clienteId', 'nombre email telefono tokenFCM');

      socket.emit('solicitud:lista', solicitudes);
      console.log(`Enviando ${solicitudes.length} solicitudes pendientes al conductor ${conductorId}`);
    } catch (err) {
      console.error('Error en solicitud:obtener:', err);
      socket.emit('solicitud:error', 'Error al obtener solicitudes');
    }
  });

  // 3. Conductor acepta o rechaza una solicitud
  socket.on('solicitud:actualizar', async (data) => {
    try {
      const { solicitudId, estado } = data;

      if (!['pendiente', 'aceptada', 'rechazada', 'finalizada'].includes(estado)) {
        return socket.emit('solicitud:error', 'Estado inválido');
      }

      const solicitud = await SolicitudTransporte.findByIdAndUpdate(
        solicitudId,
        { estado },
        { new: true }
      ).populate('clienteId');

      console.log(`Solicitud ${solicitudId} actualizada a estado ${estado}`);

      socket.emit('solicitud:estadoActualizado', solicitud);

      // Notificar al cliente
      const clienteId = solicitud.clienteId._id.toString();
      io.to(`cliente_${clienteId}`).emit('solicitud:estadoActualizado', solicitud);

    } catch (err) {
      console.error('Error en solicitud:actualizar:', err);
      socket.emit('solicitud:error', 'Error al actualizar solicitud');
    }
  });

  // 4. Verificar si existe una solicitud pendiente
  socket.on('solicitud:existe', async (data) => {
    try {
      const { clienteId, conductorId } = data;
      if (!clienteId || !conductorId) {
        return socket.emit('solicitud:error', 'Faltan clienteId o conductorId');
      }

      const existe = await SolicitudTransporte.exists({
        clienteId,
        conductorId,
        estado: 'pendiente',
      });

      socket.emit('solicitud:existeRespuesta', { existe: !!existe });
    } catch (err) {
      console.error('Error en solicitud:existe:', err);
      socket.emit('solicitud:error', 'Error al verificar existencia');
    }
  });

};
