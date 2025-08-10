import express from 'express';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import http from 'http';
import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import Message from './models/message.model';
import path from 'path';

import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import uploadRoutes from './routes/upload.routes';
import chatRoutes from './routes/chat.routes';
import messageRoutes from './routes/message.routes';
import conversationRoutes from './routes/conversation.routes';

dotenv.config();

const app = express();

app.use(express.json());
app.use('/uploads', express.static(path.resolve(__dirname, '..', 'uploads')));

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/upload', uploadRoutes);
app.use('/chats', chatRoutes);
app.use('/messages', messageRoutes);
app.use('/conversations', conversationRoutes);

app.get('/', (req, res) => {
  res.send('Hello World');
});

// Criação do servidor HTTP e Socket.IO
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

// Autenticação de socket via token JWT (query ?token=...)
io.use((socket, next) => {
  const token = socket.handshake.query?.token as string | undefined;
  if (!token) return next(new Error('Sem token'));
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET as string);
    // @ts-ignore
    socket.data.user = decoded; // guarda payload
    next();
  } catch (e) {
    next(new Error('Token inválido'));
  }
});

io.on('connection', (socket) => {
  // @ts-ignore
  const userId = socket.data.user?.id;
  if (userId) socket.join(userId); // sala individual do usuário

  socket.on('message:send', async (payload: { to: string; content: string; type?: string }) => {
    try {
      if (!payload?.to || !payload?.content) return;
      const type = (payload.type === 'sticker') ? 'sticker' : 'text';
      const message = new Message({ from: userId, to: payload.to, content: payload.content, type });
      await message.save();
      const dto = {
        id: message._id,
        from: message.from,
        to: message.to,
        content: message.content,
        type: message.type,
        timestamp: message.timestamp
      };
      // Emite para remetente e destinatário
      io.to(userId).emit('message:new', dto);
      io.to(payload.to).emit('message:new', dto);
    } catch (err) {
      socket.emit('error', { message: 'Falha ao enviar mensagem' });
    }
  });

  socket.on('disconnect', () => {
    // opcional: log
  });
});

mongoose.connect(process.env.MONGODB_URI as string)
  .then(() => {
    console.log("Concectado com sucesso ao MongoDB");
    server.listen(process.env.PORT, () => {
      console.log(`Servidor HTTP & Socket.IO rodando na porta ${process.env.PORT}`);
    });
  })
  .catch(err => {
    console.error("Erro ao conectar ao MongoDB", err);
  });