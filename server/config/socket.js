let io;

module.exports = {
  initSocket: (server) => {
    io = require('socket.io')(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      }
    });

    io.on('connection', (socket) => {
      console.log('Cliente conectado:', socket.id);

      // Delegar a los controladores de WebSocket
      require('../app/sockets/conductor.socket')(socket, io);
      require('../app/sockets/cliente.socket')(socket, io);


      socket.on('disconnect', () => {
        console.log('Cliente desconectado:', socket.id);
      });
    });

    return io;
  },

  getSocket: () => {
    if (!io) {
      throw new Error('Socket.io no ha sido inicializado');
    }
    return io;
  }
};
