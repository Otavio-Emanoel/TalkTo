import { Router } from 'express';
import { getChatHistory } from '../controllers/chat.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Rota protegida para histórico de conversa entre usuários
router.get('/:userId', authenticateJWT, getChatHistory);

export default router;
