const Cliente = require('../models/cliente');
const Conductor = require('../models/conductor');

const verificarCodigo = async (req, res) => {
  try {
    const { email, codigo } = req.body;

    if (!email || !codigo) {
      return res.status(400).json({ error: 'Email y código son obligatorios' });
    }

    // Buscar cliente
    let usuario = await Cliente.findOne({ email });
    let tipo = 'cliente';

    if (!usuario) {
      usuario = await Conductor.findOne({ email });
      tipo = 'conductor';
    }

    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    if (usuario.verificationCode !== codigo) {
      return res.status(400).json({ error: 'Código de verificación incorrecto' });
    }

    usuario.emailVerificado = true;
    usuario.verificationCode = undefined; // Limpiar código si ya fue usado
    await usuario.save();

    res.json({ message: `${tipo} verificado correctamente`, emailVerificado: true });

  } catch (e) {
    console.error("Error en verificarCodigo:", e);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = { verificarCodigo };
