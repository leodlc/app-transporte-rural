// app/socket-tests/clienteUbicacionTest.js

const { io } = require('socket.io-client');

// Cambia esto si tu backend corre en otro host o puerto
const socket = io("http://localhost:3000");

// Datos quemados para pruebas
const clienteId = '68537a66f4c9d40c6a62b945'; // Asegúrate de que este ID exista
const lat = -0.22985;
const lng = -78.52432;

socket.on('connect', () => {
  console.log('Conectado al servidor WebSocket');

  // Enviar ubicación al conectar
  const payload = { clienteId, lat, lng };
  socket.emit('cliente:ubicacion-actualizar', payload);
  console.log('Ubicación enviada:', payload);

  // Desactivar ubicación después de 30 segundos
  setTimeout(() => {
    socket.emit('cliente:ubicacion-desactivar', { clienteId });
    console.log('Solicitud para desactivar ubicación enviada');
  }, 30000);
});

socket.on('cliente-ubicacion-actualizada', (data) => {
  console.log('Ubicación actualizada desde el servidor:', data);
});

socket.on('cliente-ubicacion-desactivada', (data) => {
  console.log('Ubicación desactivada desde el servidor:', data);
});

socket.on('disconnect', () => {
  console.log('Desconectado del servidor');
});
