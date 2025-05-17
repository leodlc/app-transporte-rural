const httpError = (res, err) => {
    console.error(err); // Mostrar el error completo en la consola
    res.status(500);
    res.send({ error: 'Algo salió mal', details: err.message });
  };
  
  module.exports = { httpError };
  