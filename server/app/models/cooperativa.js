const mongoose = require('mongoose');

const CooperativaSchema = new mongoose.Schema({
    nombre: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    responsable: { type: String, required: true, unique: true },
    ubicacion: { type: String, required: true },
    telefono: { type: String, required: true },
    }, { timestamps: true, versionKey: false }
);

module.exports = mongoose.model('Cooperativa', CooperativaSchema);