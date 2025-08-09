import { Router } from 'express';
import { sendMessage } from '../controllers/message.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// Rota protegida para enviar mensagem
router.post('/', authenticateJWT, sendMessage);

export default router;
