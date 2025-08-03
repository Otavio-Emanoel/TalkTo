import express from 'express';
import dotenv from 'dotenv';
import mongoose from 'mongoose';

dotenv.config();

const app = express();

app.get('/', (req, res) => {
  res.send('Hello World');
});

mongoose.connect(process.env.MONGODB_URI as string)
  .then(() => {
    console.log("Concectado com sucesso ao MongoDB");
    app.listen(process.env.PORT, () => {
      console.log(`O server ta rodando na porta ${process.env.PORT}`);
    });
  })
  .catch(err => {
    console.error("Erro ao conectar ao MongoDB", err);
  });