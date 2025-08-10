import { Router } from 'express';
import { getUsers, getUser, updateUser, updateBio } from '../controllers/user.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Rota protegida para listar todos os usuários exceto o logado

// Rota protegida para buscar dados de um usuário específico
router.get('/:id', authenticateJWT, getUser);

router.get('/', authenticateJWT, getUsers);

// Atualizar usuário autenticado
router.put('/:id', authenticateJWT, updateUser);
router.put('/:id/bio', authenticateJWT, updateBio);

export default router;
