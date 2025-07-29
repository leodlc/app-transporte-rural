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
      const { tipo, id } = socket.handshake.query;

      if (tipo === 'cliente') {
        socket.join(`cliente_${id}`);
        console.log(`Cliente ${id} conectado`);
      } else if (tipo === 'conductor') { 
        socket.join(`conductor_${id}`);
        console.log(`Conductor ${id} conectado`);
      }

      console.log(socket.handshake.query);
      console.log('Usuario conectado:', socket.id);



      socket.on('disconnect', () => {
        console.log(`Usuario desconectado: ${socket.id}`);
      });

      // Delegar a los controladores de WebSocket
      require('../app/sockets/viaje.socket')(socket, io);
      require('../app/sockets/conductor.socket')(socket, io);
      require('../app/sockets/cliente.socket')(socket, io);
      require('../app/sockets/solicitud.socket')(socket, io);

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
