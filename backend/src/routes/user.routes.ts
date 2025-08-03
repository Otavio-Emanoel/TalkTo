import { Router } from 'express';
import { getUsers, getUser } from '../controllers/user.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Rota protegida para listar todos os usuários exceto o logado

// Rota protegida para buscar dados de um usuário específico
router.get('/:id', authenticateJWT, getUser);

router.get('/', authenticateJWT, getUsers);

export default router;
