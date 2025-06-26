const mongoose = require('mongoose');

const ClienteSchema = new mongoose.Schema({
  nombre: { type: String, required: true },
  username: { type: String, required: true },
  telefono: { type: String, required: false },
  email: { type: String, unique: true },
  password: { type: String, required: true },
  tokenFCM: [{ type: String }], // Para múltiples dispositivos, // Para notificaciones push
  activo: { type: Boolean, default: true },
  rol: { type: String, enum: ['cliente'], default: 'cliente', required: true }, // Campo obligatorio de rol
  verificationCode: { type: String },
  emailVerificado: { type: Boolean, default: false },
  direccion: { type: mongoose.Schema.Types.ObjectId, ref: 'Direccion', required: false }, // Relación con dirección
  ubicacionActiva: { type: Boolean, default: false },
  

}, { timestamps: true, versionKey: false });

module.exports = mongoose.model('Cliente', ClienteSchema);