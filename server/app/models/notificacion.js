// models/notificacion.js
const mongoose = require('mongoose');

const NotificacionSchema = new mongoose.Schema({
  usuarioId: { type: mongoose.Schema.Types.ObjectId, required: true }, // receptor
  rol: { type: String, enum: ['cliente', 'conductor', 'admin'], required: true },
  emisorId: { type: mongoose.Schema.Types.ObjectId, required: true },
  rolEmisor: { type: String, enum: ['cliente', 'conductor', 'admin'], required: true },
  titulo: { type: String },
  cuerpo: { type: String },
  enviadoEn: { type: Date, default: Date.now }
}, { timestamps: true });


module.exports = mongoose.model('Notificacion', NotificacionSchema);
