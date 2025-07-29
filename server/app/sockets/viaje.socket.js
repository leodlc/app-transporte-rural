const Viaje = require('../models/viaje');
const Cliente = require('../models/cliente');
const Conductor = require('../models/conductor');
const SolicitudTransporte = require('../models/solicitudTransporte');
const Ubicacion = require('../models/ubicacion');

module.exports = (socket, io) => {

  // 1. Iniciar viaje cuando el conductor acepta una solicitud
  socket.on('viaje:iniciar', async (data) => {
    try {
      const { solicitudId, conductorId, clienteId } = data;

      if (!solicitudId || !conductorId || !clienteId) {
        return socket.emit('viaje:error', 'Datos requeridos: solicitudId, conductorId, clienteId');
      }

      // Verificar que la solicitud existe y está aceptada
      const solicitud = await SolicitudTransporte.findById(solicitudId);
      if (!solicitud || solicitud.estado !== 'aceptada') {
        return socket.emit('viaje:error', 'Solicitud no válida o no aceptada');
      }

      // Verificar que no existe un viaje activo para estos usuarios
      const viajeExistente = await Viaje.findOne({
        $or: [
          { clienteId, estado: { $in: ['iniciado', 'en_curso', 'llegando'] } },
          { conductorId, estado: { $in: ['iniciado', 'en_curso', 'llegando'] } }
        ]
      });

      if (viajeExistente) {
        return socket.emit('viaje:error', 'Ya existe un viaje activo');
      }

      // Crear nuevo viaje
      const viaje = await Viaje.create({
        clienteId,
        conductorId,
        solicitudId,
        estado: 'iniciado',
        fechaInicio: new Date()
      });

      const viajePopulado = await Viaje.findById(viaje._id)
        .populate('clienteId', 'nombre telefono')
        .populate('conductorId', 'nombre telefono placa');

      // Unir a ambos usuarios a una sala específica del viaje
      const salaViaje = `viaje_${viaje._id}`;
      socket.join(salaViaje);

      // Notificar a ambos usuarios
      io.to(`cliente_${clienteId}`).emit('viaje:iniciado', {
        viaje: viajePopulado,
        salaViaje
      });
      
      io.to(`conductor_${conductorId}`).emit('viaje:iniciado', {
        viaje: viajePopulado,
        salaViaje
      });

      console.log(`Viaje iniciado: ${viaje._id} entre cliente ${clienteId} y conductor ${conductorId}`);

    } catch (err) {
      console.error('Error en viaje:iniciar:', err);
      socket.emit('viaje:error', 'Error al iniciar el viaje');
    }
  });

  // 2. Unirse a la sala de un viaje existente
  socket.on('viaje:unirse', async (data) => {
    try {
      const { viajeId, usuarioId, tipoUsuario } = data; // tipoUsuario: 'cliente' o 'conductor'

      if (!viajeId || !usuarioId || !tipoUsuario) {
        return socket.emit('viaje:error', 'Datos requeridos: viajeId, usuarioId, tipoUsuario');
      }

      const viaje = await Viaje.findById(viajeId)
        .populate('clienteId', 'nombre telefono')
        .populate('conductorId', 'nombre telefono placa');

      if (!viaje) {
        return socket.emit('viaje:error', 'Viaje no encontrado');
      }

      // Verificar que el usuario pertenece al viaje
      const esCliente = tipoUsuario === 'cliente' && viaje.clienteId._id.toString() === usuarioId;
      const esConductor = tipoUsuario === 'conductor' && viaje.conductorId._id.toString() === usuarioId;

      if (!esCliente && !esConductor) {
        return socket.emit('viaje:error', 'No autorizado para este viaje');
      }

      const salaViaje = `viaje_${viajeId}`;
      socket.join(salaViaje);

      socket.emit('viaje:unido', {
        viaje,
        salaViaje,
        tipoUsuario
      });

      console.log(`${tipoUsuario} ${usuarioId} se unió al viaje ${viajeId}`);

    } catch (err) {
      console.error('Error en viaje:unirse:', err);
      socket.emit('viaje:error', 'Error al unirse al viaje');
    }
  });

  // 3. Compartir ubicación en tiempo real durante el viaje
  socket.on('viaje:ubicacion-actualizar', async (data) => {
    try {
      const { viajeId, usuarioId, tipoUsuario, lat, lng } = data;

      if (!viajeId || !usuarioId || !tipoUsuario || typeof lat !== 'number' || typeof lng !== 'number') {
        console.log('Datos inválidos para ubicación:', data);
        return;
      }

      const viaje = await Viaje.findById(viajeId);
      if (!viaje || !['iniciado', 'en_curso', 'llegando'].includes(viaje.estado)) {
        return socket.emit('viaje:error', 'Viaje no válido para actualizar ubicación');
      }

      // Verificar que el usuario pertenece al viaje
      const esCliente = tipoUsuario === 'cliente' && viaje.clienteId.toString() === usuarioId;
      const esConductor = tipoUsuario === 'conductor' && viaje.conductorId.toString() === usuarioId;

      if (!esCliente && !esConductor) {
        return;
      }

      const salaViaje = `viaje_${viajeId}`;
      const payload = {
        viajeId,
        usuarioId,
        tipoUsuario,
        lat,
        lng,
        timestamp: new Date().toISOString()
      };

      // Emitir a todos en la sala del viaje (excluir al emisor)
      socket.to(salaViaje).emit('viaje:ubicacion-recibida', payload);

      // Opcional: Guardar última ubicación en el viaje
      const campoUbicacion = tipoUsuario === 'cliente' ? 'ubicacionCliente' : 'ubicacionConductor';
      await Viaje.findByIdAndUpdate(viajeId, {
        [campoUbicacion]: { lat, lng, actualizado: new Date() }
      });

      console.log(`Ubicación actualizada en viaje ${viajeId} por ${tipoUsuario} ${usuarioId}`);

    } catch (err) {
      console.error('Error en viaje:ubicacion-actualizar:', err);
    }
  });

  // 4. Conductor indica que está llegando
  socket.on('viaje:llegando', async (data) => {
    try {
      const { viajeId, conductorId } = data;

      if (!viajeId || !conductorId) {
        return socket.emit('viaje:error', 'viajeId y conductorId son requeridos');
      }

      const viaje = await Viaje.findById(viajeId);
      if (!viaje || viaje.conductorId.toString() !== conductorId) {
        return socket.emit('viaje:error', 'Viaje no válido o conductor no autorizado');
      }

      if (viaje.estado !== 'iniciado') {
        return socket.emit('viaje:error', 'El viaje debe estar en estado iniciado');
      }

      // Actualizar estado del viaje
      viaje.estado = 'llegando';
      viaje.horaLlegada = new Date();
      await viaje.save();

      const salaViaje = `viaje_${viajeId}`;
      
      // Notificar a ambos usuarios
      io.to(salaViaje).emit('viaje:conductor-llegando', {
        viajeId,
        conductorId,
        mensaje: 'El conductor está llegando a tu ubicación',
        timestamp: new Date().toISOString()
      });

      console.log(`Conductor ${conductorId} llegando al viaje ${viajeId}`);

    } catch (err) {
      console.error('Error en viaje:llegando:', err);
      socket.emit('viaje:error', 'Error al actualizar estado a llegando');
    }
  });

  // 5. Comenzar el viaje (cuando el conductor llega donde el cliente)
  socket.on('viaje:comenzar', async (data) => {
    try {
      const { viajeId, conductorId } = data;

      if (!viajeId || !conductorId) {
        return socket.emit('viaje:error', 'viajeId y conductorId son requeridos');
      }

      const viaje = await Viaje.findById(viajeId);
      if (!viaje || viaje.conductorId.toString() !== conductorId) {
        return socket.emit('viaje:error', 'Viaje no válido o conductor no autorizado');
      }

      if (!['iniciado', 'llegando'].includes(viaje.estado)) {
        return socket.emit('viaje:error', 'El viaje debe estar iniciado o en estado llegando');
      }

      // Actualizar estado del viaje
      viaje.estado = 'en_curso';
      viaje.horaComienzoViaje = new Date();
      await viaje.save();

      const viajePopulado = await Viaje.findById(viajeId)
        .populate('clienteId', 'nombre telefono')
        .populate('conductorId', 'nombre telefono placa');

      const salaViaje = `viaje_${viajeId}`;
      
      // Notificar a ambos usuarios
      io.to(salaViaje).emit('viaje:comenzado', {
        viaje: viajePopulado,
        mensaje: 'El viaje ha comenzado',
        timestamp: new Date().toISOString()
      });

      console.log(`Viaje ${viajeId} comenzado por conductor ${conductorId}`);

    } catch (err) {
      console.error('Error en viaje:comenzar:', err);
      socket.emit('viaje:error', 'Error al comenzar el viaje');
    }
  });

  // 6. Terminar el viaje
  socket.on('viaje:terminar', async (data) => {
    try {
      const { viajeId, conductorId, ubicacionFinal } = data;

      if (!viajeId || !conductorId) {
        return socket.emit('viaje:error', 'viajeId y conductorId son requeridos');
      }

      const viaje = await Viaje.findById(viajeId);
      if (!viaje || viaje.conductorId.toString() !== conductorId) {
        return socket.emit('viaje:error', 'Viaje no válido o conductor no autorizado');
      }

      if (viaje.estado !== 'en_curso') {
        return socket.emit('viaje:error', 'El viaje debe estar en curso para terminarlo');
      }

      // Actualizar estado del viaje
      viaje.estado = 'finalizado';
      viaje.fechaFin = new Date();
      if (ubicacionFinal) {
        viaje.ubicacionFinal = ubicacionFinal;
      }

      // Calcular duración del viaje
      if (viaje.horaComienzoViaje) {
        const duracionMs = viaje.fechaFin - viaje.horaComienzoViaje;
        viaje.duracionMinutos = Math.round(duracionMs / (1000 * 60));
      }

      await viaje.save();

      // Actualizar solicitud relacionada
      await SolicitudTransporte.findByIdAndUpdate(viaje.solicitudId, {
        estado: 'finalizada'
      });

      const viajePopulado = await Viaje.findById(viajeId)
        .populate('clienteId', 'nombre telefono')
        .populate('conductorId', 'nombre telefono placa');

      const salaViaje = `viaje_${viajeId}`;
      
      // Notificar a ambos usuarios
      io.to(salaViaje).emit('viaje:finalizado', {
        viaje: viajePopulado,
        mensaje: 'El viaje ha finalizado',
        timestamp: new Date().toISOString()
      });

      console.log(`Viaje ${viajeId} finalizado por conductor ${conductorId}`);

      // Opcional: Hacer que los usuarios salgan de la sala
      io.in(salaViaje).socketsLeave(salaViaje);

    } catch (err) {
      console.error('Error en viaje:terminar:', err);
      socket.emit('viaje:error', 'Error al terminar el viaje');
    }
  });

  // 7. Cancelar viaje (puede ser por cliente o conductor)
  socket.on('viaje:cancelar', async (data) => {
    try {
      const { viajeId, usuarioId, tipoUsuario, motivo } = data;

      if (!viajeId || !usuarioId || !tipoUsuario) {
        return socket.emit('viaje:error', 'Datos requeridos: viajeId, usuarioId, tipoUsuario');
      }

      const viaje = await Viaje.findById(viajeId);
      if (!viaje) {
        return socket.emit('viaje:error', 'Viaje no encontrado');
      }

      // Verificar autorización
      const esCliente = tipoUsuario === 'cliente' && viaje.clienteId.toString() === usuarioId;
      const esConductor = tipoUsuario === 'conductor' && viaje.conductorId.toString() === usuarioId;

      if (!esCliente && !esConductor) {
        return socket.emit('viaje:error', 'No autorizado para cancelar este viaje');
      }

      if (['finalizado', 'cancelado'].includes(viaje.estado)) {
        return socket.emit('viaje:error', 'El viaje ya está finalizado o cancelado');
      }

      // Actualizar estado del viaje
      viaje.estado = 'cancelado';
      viaje.fechaCancelacion = new Date();
      viaje.motivoCancelacion = motivo || 'Sin motivo especificado';
      viaje.canceladoPor = tipoUsuario;
      await viaje.save();

      // Actualizar solicitud relacionada
      await SolicitudTransporte.findByIdAndUpdate(viaje.solicitudId, {
        estado: 'rechazada'
      });

      const viajePopulado = await Viaje.findById(viajeId)
        .populate('clienteId', 'nombre telefono')
        .populate('conductorId', 'nombre telefono placa');

      const salaViaje = `viaje_${viajeId}`;
      
      // Notificar a ambos usuarios
      io.to(salaViaje).emit('viaje:cancelado', {
        viaje: viajePopulado,
        canceladoPor: tipoUsuario,
        motivo: motivo || 'Sin motivo especificado',
        timestamp: new Date().toISOString()
      });

      console.log(`Viaje ${viajeId} cancelado por ${tipoUsuario} ${usuarioId}`);

      // Hacer que los usuarios salgan de la sala
      io.in(salaViaje).socketsLeave(salaViaje);

    } catch (err) {
      console.error('Error en viaje:cancelar:', err);
      socket.emit('viaje:error', 'Error al cancelar el viaje');
    }
  });

  // 8. Obtener estado actual del viaje
  socket.on('viaje:estado', async (data) => {
    try {
      const { viajeId, usuarioId, tipoUsuario } = data;

      if (!viajeId || !usuarioId || !tipoUsuario) {
        return socket.emit('viaje:error', 'Datos requeridos: viajeId, usuarioId, tipoUsuario');
      }

      const viaje = await Viaje.findById(viajeId)
        .populate('clienteId', 'nombre telefono')
        .populate('conductorId', 'nombre telefono placa')
        .populate('solicitudId');

      if (!viaje) {
        return socket.emit('viaje:error', 'Viaje no encontrado');
      }

      // Verificar autorización
      const esCliente = tipoUsuario === 'cliente' && viaje.clienteId._id.toString() === usuarioId;
      const esConductor = tipoUsuario === 'conductor' && viaje.conductorId._id.toString() === usuarioId;

      if (!esCliente && !esConductor) {
        return socket.emit('viaje:error', 'No autorizado para ver este viaje');
      }

      socket.emit('viaje:estado-actual', {
        viaje,
        salaViaje: `viaje_${viajeId}`
      });

      console.log(`Estado del viaje ${viajeId} enviado a ${tipoUsuario} ${usuarioId}`);

    } catch (err) {
      console.error('Error en viaje:estado:', err);
      socket.emit('viaje:error', 'Error al obtener estado del viaje');
    }
  });

  // Evento de desconexión
  socket.on('disconnect', () => {
    console.log('Cliente desconectado de viaje.socket.js');
  });

};