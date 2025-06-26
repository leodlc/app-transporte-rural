const cron = require('node-cron');
const SolicitudTransporte = require('../models/solicitudTransporte');

const iniciarJobExpiracionSolicitudes = () => {
  cron.schedule('* * * * *', async () => {
    try {
      const cincoMinutosAtras = new Date(Date.now() - 5 * 60 * 1000);

      const solicitudesExpiradas = await SolicitudTransporte.find({
        estado: 'pendiente',
        createdAt: { $lte: cincoMinutosAtras }
      });

      if (solicitudesExpiradas.length > 0) {
        for (const solicitud of solicitudesExpiradas) {
          solicitud.estado = 'rechazada';
          await solicitud.save();
          console.log(`Solicitud expirada y rechazada automáticamente: ${solicitud._id}`);
        }
      }
    } catch (error) {
      console.error('Error al procesar expiración de solicitudes:', error);
    }
  });

  console.log('Job de expiración de solicitudes iniciado (cada 1 minuto)');
};

module.exports = iniciarJobExpiracionSolicitudes;
