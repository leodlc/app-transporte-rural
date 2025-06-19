require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { dbConnection } = require('./config/mongo');
require('./config/firebase'); // Asegura que Firebase se inicializa
const { initSocket } = require('./config/socket'); // importar socket

const app = express();
const server = http.createServer(app); // Crear servidor HTTP
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'

app.use(cors());
app.use(express.json());

// Cargar rutas automáticamente desde `routes/index.js`
app.use('/api/1.0', require('./app/routes'));

dbConnection().then(() => {
  const io = initSocket(server); // inicializar socket.io

  server.listen(PORT, HOST, () => {
    console.log(`Servidor corriendo en http://${HOST}:${PORT}`);
  });
}).catch(error => {
  console.error('Database connection failed', error);
  process.exit(1);
});