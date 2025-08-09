import express from 'express';
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import uploadRoutes from './routes/upload.routes';

dotenv.config();

const app = express();

app.use(express.json());

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/upload', uploadRoutes);

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