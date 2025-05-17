const express = require('express');
const router = express.Router();

const fs = require('fs');

const pathRouter = `${__dirname}`;

const removeExtension = (fileName) => {
    return fileName.split('.').shift();
}

fs.readdirSync(pathRouter).filter((file) => {
    const fileWithoutExt = removeExtension(file);
    const skip = ['index'].includes(fileWithoutExt);
    if(!skip){
        router.use(`/${fileWithoutExt}`, require(`./${fileWithoutExt}`)); //TODO: localhost/publications
        console.log('LOAD ROUTE ----->', fileWithoutExt);

    }
    
})

router.get('*', (req, res) => {
    res.status(404);
    res.send({error:'No se ha encontrado la ruta'});
})

module.exports = router;