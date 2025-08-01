const Viaje = require('../models/viaje');

const verificarViajeActivo = async (req, res) => {
  const { id } = req.params;

  try {
    const viajeExistente = await Viaje.findOne({
      $or: [
        { clienteId: id, estado: { $in: ['iniciado', 'en_curso', 'llegando'] } },
        { conductorId: id, estado: { $in: ['iniciado', 'en_curso', 'llegando'] } }
      ]
    })
    // Poblamos clienteId
    .populate('clienteId', 'nombre telefono')
    // Poblamos conductorId y dentro de éste su vehiculo
    .populate({
      path: 'conductorId',
      select: 'nombre telefono email',
      populate: {
        path: 'vehiculo',
        model: 'Vehiculo',         // Asegúrate de que el nombre coincida con el model mongoose
        select: 'marca modelo placa rmt' // Solo los campos que necesites
      }
    })
    // Poblamos solicitudId
    .populate('solicitudId', 'origen destino');

    if (viajeExistente) {
      return res.status(200).json({
        viajeExistente: true,
        viaje: viajeExistente
      });
    } else {
      return res.status(200).json({
        viajeExistente: false
      });
    }
  } catch (error) {
    console.error("Error en verificarViajeActivo:", error);
    return res.status(500).json({ error: 'Error al verificar viaje activo' });
  }
};

module.exports = { verificarViajeActivo };
