import { Request, Response } from 'express';
import Message from '../models/message.model';

export const sendMessage = async (req: Request, res: Response) => {
  try {
    const { to, content, type } = req.body;
    // @ts-ignore
    const from = req.user?.id;
    if (!from || !to || !content || !type) {
      return res.status(400).json({ message: 'Campos obrigatórios ausentes.' });
    }
    const message = new Message({ from, to, content, type });
    await message.save();
    res.status(201).json({ message: 'Mensagem enviada com sucesso!', data: message });
  } catch (err) {
    res.status(500).json({ message: 'Erro ao enviar mensagem', error: err });
  }
};
