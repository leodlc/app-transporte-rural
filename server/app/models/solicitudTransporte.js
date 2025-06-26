const mongoose = require('mongoose');

const SolicitudTransporteSchema = new mongoose.Schema({
  clienteId: { type: mongoose.Schema.Types.ObjectId, ref: 'Cliente', required: true },
  conductorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conductor', required: true },
  estado: { type: String, enum: ['pendiente', 'aceptada', 'rechazada', 'finalizada'], default: 'pendiente' },
  fecha: { type: Date, default: Date.now }
}, { timestamps: true, versionKey: false });

module.exports = mongoose.model('SolicitudTransporte', SolicitudTransporteSchema);
