import { Request, Response } from 'express';
import User from '../models/user.model';

export const uploadPhoto = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    if (!req.file) {
      return res.status(400).json({ message: 'Arquivo não enviado.' });
    }
    const photoURL = `/uploads/${req.file.filename}`;
    const user = await User.findByIdAndUpdate(id, { photoURL }, { new: true }).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }
    res.json({ message: 'Foto atualizada!', user });
  } catch (err) {
    res.status(500).json({ message: 'Erro ao fazer upload', error: err });
  }
};
