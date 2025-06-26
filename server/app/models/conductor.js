const mongoose = require('mongoose');

const ConductorSchema = new mongoose.Schema({
  nombre: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  username: { type: String, required: true, unique: true }, // Nombre de usuario único
  cooperativa: { type: mongoose.Schema.Types.ObjectId, ref: 'Cooperativa' }, // Relación con cooperativa
  telefono: { type: String, required: true },
  password: { type: String, required: true }, // Se requiere para autenticación
  vehiculo: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehiculo' }, // Relación con vehículo
  ubicacion: { type: mongoose.Schema.Types.ObjectId, ref: 'Ubicacion'}, // Relación con ubicación
  //pedidosAsignados: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Pedido' }], // Pedidos en curso
  tokenFCM: [{ type: String }], // Token para recibir notificaciones
  activo: { type: Boolean, default: true },
  verificationCode: { type: String },
  rol: { type: String, enum: ['conductor'], default: 'conductor', required: true }, // Campo obligatorio de rol
  emailVerificado: { type: Boolean, default: false },
  ubicacionActiva: { type: Boolean, default: false },


}, { timestamps: true, versionKey: false });

module.exports = mongoose.model('Conductor', ConductorSchema);
