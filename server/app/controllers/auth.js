const Cliente = require('../models/cliente');
const Conductor = require('../models/conductor');
const Admin = require('../models/admin');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { httpError } = require('../helpers/handleError');

const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Buscar el usuario
    let usuario = await Cliente.findOne({ username }) ||
                  await Conductor.findOne({ username }) ||
                  await Admin.findOne({ username });

    if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

    const isMatch = await bcrypt.compare(password, usuario.password);
    if (!isMatch) return res.status(400).json({ error: 'Contraseña incorrecta' });

    let activo = usuario.activo ?? true;

    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Determinar si es cliente o conductor y si tiene emailVerificado
    let emailVerificado = false;

    if (usuario instanceof Cliente || usuario.rol === 'cliente') {
      const cliente = await Cliente.findById(usuario._id).select('emailVerificado');
      emailVerificado = cliente?.emailVerificado ?? false;
    }

    if (usuario instanceof Conductor || usuario.rol === 'conductor') {
      const conductor = await Conductor.findById(usuario._id).select('emailVerificado');
      emailVerificado = conductor?.emailVerificado ?? false;
    }

    res.json({
      message: 'Inicio de sesión exitoso',
      token,
      usuario: {
        id: usuario._id,
        rol: usuario.rol,
        activo,
        emailVerificado
      }
    });

  } catch (e) {
    console.error("Error en login:", e);
    httpError(res, e);
  }
};

module.exports = { login };
