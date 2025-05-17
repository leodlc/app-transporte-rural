require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { dbConnection } = require('./config/mongo');
//require('./config/firebase'); // Asegura que Firebase se inicializa

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'

app.use(cors());
app.use(express.json());

// Cargar rutas automáticamente desde `routes/index.js`
app.use('/api/1.0', require('./app/routes'));

dbConnection().then(() => {
  app.listen(PORT,HOST, () => {
    console.log(`Server running on port ${PORT}`);
  });
}).catch(error => {
  console.error('Database connection failed', error);
  process.exit(1);
});