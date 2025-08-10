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

// Atualizar dados do usuário autenticado
export const updateUser = async (req: Request, res: Response) => {
  try {
    const authUserId = req.user?.id; // setado pelo middleware
    const { id } = req.params;
    if (!authUserId) {
      return res.status(401).json({ message: 'Não autenticado.' });
    }
    if (authUserId !== id) {
      return res.status(403).json({ message: 'Acesso negado para editar este usuário.' });
    }
    const { name, phone, photoURL, email } = req.body;
    const fieldsToUpdate: any = {};
    if (name !== undefined) fieldsToUpdate.name = name;
    if (phone !== undefined) fieldsToUpdate.phone = phone;
    if (photoURL !== undefined) fieldsToUpdate.photoURL = photoURL;
    if (email !== undefined) fieldsToUpdate.email = email;

    if (Object.keys(fieldsToUpdate).length === 0) {
      return res.status(400).json({ message: 'Nenhum campo para atualizar.' });
    }

    const updated = await User.findByIdAndUpdate(
      id,
      { $set: fieldsToUpdate },
      { new: true, runValidators: true, projection: '-password' }
    );
    if (!updated) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }
    res.json(updated);
  } catch (err: any) {
    // Tratar erro de chave duplicada (email/phone únicos)
    if (err?.code === 11000) {
      return res.status(409).json({ message: 'Valor duplicado em campo único.', keyValue: err.keyValue });
    }
    res.status(500).json({ message: 'Erro ao atualizar usuário', error: err });
  }
};

// Atualizar bio do usuário autenticado
export const updateBio = async (req: Request, res: Response) => {
  try {
    const authUserId = req.user?.id; // setado pelo middleware
    const { id } = req.params;
    if (!authUserId) {
      return res.status(401).json({ message: 'Não autenticado.' });
    }
    if (authUserId !== id) {
      return res.status(403).json({ message: 'Acesso negado para editar este usuário.' });
    }
    const { bio } = req.body;
    if (!bio) {
      return res.status(400).json({ message: 'Bio é obrigatória.' });
    }
    const updated = await User.findByIdAndUpdate(
      id,
      { $set: { bio } },
      { new: true, runValidators: true, projection: '-password' }
    );
    if (!updated) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Erro ao atualizar bio', error: err });
  }
}