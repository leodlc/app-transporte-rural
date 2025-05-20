const mongoose = require('mongoose');

const UbicacionSchema = new mongoose.Schema({
  lat: { type: Number, required: true },
  lng: { type: Number, required: true }
}, { timestamps: true, versionKey: false });
//
module.exports = mongoose.model('Ubicacion', UbicacionSchema);
