// models/viaje.js
const mongoose = require('mongoose');

const viajeSchema = new mongoose.Schema({
  clienteId: { type: mongoose.Schema.Types.ObjectId, ref: 'Cliente', required: true },
  conductorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conductor', required: true },
  solicitudId: { type: mongoose.Schema.Types.ObjectId, ref: 'SolicitudTransporte', required: true },
  estado: { 
    type: String, 
    enum: ['iniciado', 'llegando', 'en_curso', 'finalizado', 'cancelado'],
    default: 'iniciado'
  },
  fechaInicio: { type: Date, default: Date.now },
  horaLlegada: Date,
  horaComienzoViaje: Date,
  fechaFin: Date,
  fechaCancelacion: Date,
  duracionMinutos: Number,
  ubicacionCliente: {
    lat: Number,
    lng: Number,
    actualizado: Date
  },
  ubicacionConductor: {
    lat: Number,  
    lng: Number,
    actualizado: Date
  },
  ubicacionFinal: {
    lat: Number,
    lng: Number
  },
  motivoCancelacion: String,
  codigoSeguridad: String,
  intentosCodigoSeguridad: Number,
  canceladoPor: { type: String, enum: ['cliente', 'conductor', 'sistema'] }
}, { timestamps: true });

module.exports = mongoose.model('Viaje', viajeSchema);