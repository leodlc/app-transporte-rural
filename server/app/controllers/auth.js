const Cliente = require('../models/cliente');
/* const Conductor = require('../models/conductor'); */
/* const Admin = require('../models/admin'); */
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { httpError } = require('../helpers/handleError');

const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Buscar el usuario en las tres colecciones
    /* let usuario = await Cliente.findOne({ username }) || 
                  await Conductor.findOne({ username }) || 
                  await Admin.findOne({ username });



    if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' }); */


    let usuario = await Cliente.findOne({ username });
    if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });      
    // Comparar contraseña
    const isMatch = await bcrypt.compare(password, usuario.password);
    if (!isMatch) return res.status(400).json({ error: 'Contraseña incorrecta' });

    // Generar token JWT con el rol
    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ message: 'Inicio de sesión exitoso', token, usuario: { id: usuario._id, rol: usuario.rol } });
  } catch (e) {
    console.error("Error en login:", e);
    httpError(res, e);
  }
};

module.exports = { login };