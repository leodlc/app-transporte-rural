const mongoose = require('mongoose');

const DireccionSchema = new mongoose.Schema({
  calle: { type: String, required: false },
  parroquia: { type: String, required: false },
  ciudad: { type: String, required: false },
  ubicacion: { type: mongoose.Schema.Types.ObjectId, ref: 'Ubicacion', required: false } // Relación con ubicación


}, { timestamps: true, versionKey: false });

module.exports = mongoose.model('Direccion', DireccionSchema);