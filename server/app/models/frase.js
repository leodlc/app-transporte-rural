const mongoose = require('mongoose');

const FraseSchema = new mongoose.Schema({
  frase : { type: String, required: true },
}, { timestamps: true, versionKey: false });


module.exports = mongoose.model('Frase', FraseSchema);