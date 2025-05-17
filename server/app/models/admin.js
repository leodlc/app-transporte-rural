const mongoose = require('mongoose');

const AdminSchema = new mongoose.Schema({
  nombre: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // Se requiere para autenticación
  rol: { type: String, enum: ['admin'], default: 'admin', required: true }, // Campo obligatorio de rol
  tokenFCM: { type: String, required: false }, // Token para recibir notificaciones
}, { timestamps: true, versionKey: false });

module.exports = mongoose.model('Admin', AdminSchema);