const { io } = require('socket.io-client');

const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('Conectado al WebSocket');

  // Reemplaza por un ID de conductor real de tu base
  const conductorId = '68535adce7e150646be207ed';

  socket.emit('ubicacion:desactivar', { conductorId });
});

socket.on('ubicacion-conductor-desactivada', (data) => {
  console.log('Ubicación desactivada con éxito:', data);
});

socket.on('disconnect', () => {
  console.log('Desconectado del WebSocket');
});
