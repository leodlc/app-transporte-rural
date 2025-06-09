const Cliente = require('../models/cliente');
const Conductor = require('../models/conductor');

const verificarEmail = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'El campo email es obligatorio' });
    }

    const existeEnCliente = await Cliente.findOne({ email });
    const existeEnConductor = await Conductor.findOne({ email });

    if (existeEnCliente || existeEnConductor) {
      return res.status(200).json({ existe: true, message: 'El correo ya está registrado' });
    }

    res.status(200).json({ existe: false, message: 'El correo está disponible' });

  } catch (e) {
    console.error("Error en verificarEmail:", e);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = { verificarEmail };
