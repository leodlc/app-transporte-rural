const mongoose = require('mongoose');

const ClienteSchema = new mongoose.Schema({
  nombre: { type: String, required: true },
  username: { type: String, required: true },
  telefono: { type: String, required: false },
  email: { type: String, unique: true },
  password: { type: String, required: true },
  tokenFCM: { type: String }, // Para notificaciones push
  activo: { type: Boolean, default: true },
  // Relación con dirección
  //direccion: { type: mongoose.Schema.Types.ObjectId, ref: 'Direccion', required: false },
  //pedidos: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Pedido' }], // Historial de pedidos
  rol: { type: String, enum: ['cliente'], default: 'cliente', required: true } // Campo obligatorio de rol
}, { timestamps: true, versionKey: false });

module.exports = mongoose.model('Cliente', ClienteSchema);