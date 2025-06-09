const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'leodlcm2@gmail.com',
    pass: process.env.PASSWORD_GOOGLE_EMAIL // Usa variable de entorno para mayor seguridad
  }
});

async function sendVerificationEmail(to, code) {
  const mailOptions = {
    from: '"RutaMóvil" <leodlcm2@gmail.com>',
    to,
    subject: 'Tu código de verificación - RutaMóvil',
    html: `
      <div style="font-family: Arial, sans-serif; color: #333;">
        <h2>¡Bienvenido a <span style="color: #007bff;">RutaMóvil</span>!</h2>
        <p>Gracias por unirte a nuestra comunidad.</p>
        <p>Tu código de verificación es:</p>
        <h3 style="color: #28a745;">${code}</h3>
        <hr />
        <p style="font-style: italic; color: #555;">
          RutaMóvil conecta culturas y personas, acercando comunidades rurales con un transporte digno, accesible y pensado para todos.
        </p>
      </div>
    `
  };

  return await transporter.sendMail(mailOptions);
}

module.exports = { sendVerificationEmail };
