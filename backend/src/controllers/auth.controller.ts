import User from '../models/user.model';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

export const register = async (req: any, res: any) => {
  try {
    const { name, email, password, phone, photoURL } = req.body;

    // Verifica se o usuário já existe
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'Email já cadastrado.' });
    }

    // Criptografa a senha
    const hashedPassword = await bcrypt.hash(password, 10);

    // Cria o usuário
    const user = new User({
      name,
      email,
      password: hashedPassword,
      phone,
      photoURL,
    });

    await user.save();

    res.status(201).json({ message: 'Usuário cadastrado com sucesso!' });
  } catch (err) {
    res.status(500).json({ message: 'Erro ao cadastrar usuário.', error: err });
  }
};

export const login = async (req: any, res: any) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Email e senha são obrigatórios.' });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Senha incorreta.' });
    }
    const token = jwt.sign(
      { id: user._id, email: user.email },
      process.env.JWT_SECRET as string,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        photoURL: user.photoURL,
        phone: user.phone
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Erro no login', error: err });
  }
};