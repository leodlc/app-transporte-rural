const { io } = require('socket.io-client');

// Configura la URL según tu entorno
const socket = io("http://0.0.0.0:3000");

// Datos de prueba (puedes cambiarlos)
const conductorId = '68535adce7e150646be207ed';
const lat = -0.2101222;
const lng = -78.5100132;

socket.on('connect', () => {
  console.log('✅ Conectado al WebSocket');

  // Enviar ubicación al conectarse
  socket.emit('ubicacion:actualizar', {
    conductorId: conductorId.trim(), // Elimina espacios por si acaso
    lat,
    lng
  });

  console.log(`📤 Ubicación enviada: ${lat}, ${lng} para conductor ${conductorId}`);
});

socket.on('disconnect', () => {
  console.log('🔌 Desconectado del servidor');
});

socket.on('ubicacion-conductor-actualizada', (data) => {
  console.log('📡 Respuesta del servidor:', data);
});
