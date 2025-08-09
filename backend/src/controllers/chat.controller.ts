import { Request, Response } from 'express';
import Message from '../models/message.model';

// Busca o histórico de conversa entre o usuário logado e outro usuário
export const getChatHistory = async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const loggedUserId = req.user.id;
    const otherUserId = req.params.userId;

    // Busca todas as mensagens entre os dois usuários
    const messages = await Message.find({
      $or: [
        { from: loggedUserId, to: otherUserId },
        { from: otherUserId, to: loggedUserId }
      ]
    }).sort({ timestamp: 1 });

    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: 'Erro ao buscar histórico de conversa', error: err });
  }
};
