import { Response } from 'express';
import type { Request } from 'express';
// Declaração para extender o tipo Request do Express com a propriedade 'user'
declare module 'express-serve-static-core' {
  interface Request {
    user?: {
      id: string;
      [key: string]: any;
    };
  }
}
import User from '../models/user.model';

export const getUsers = async (req: Request, res: Response) => {
  try {
    // Exclui o usuário logado da lista
    // @ts-ignore
    const userId = (req.user && req.user.id) ? req.user.id : undefined;
    if (!userId) {
      return res.status(400).json({ message: 'Usuário não autenticado.' });
    }
    const users = await User.find({ _id: { $ne: userId } }).select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: 'Erro ao buscar usuários', error: err });
  }
};

// Buscar dados de um usuário específico
export const getUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: 'Erro ao buscar usuário', error: err });
  }
};
