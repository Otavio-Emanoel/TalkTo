import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

const JWT_SECRET = process.env.JWT_SECRET as string;

export function authenticateJWT(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Token não fornecido.' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (typeof decoded === 'string' || !decoded) {
      return res.status(403).json({ message: 'Token inválido ou expirado.' });
    }
    req.user = decoded as { id: string; [key: string]: any };
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Token inválido ou expirado.' });
  }
}
