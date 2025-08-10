import { Router } from 'express';
import { authenticateJWT } from '../middlewares/auth.middleware';
import { getConversations } from '../controllers/conversation.controller';

const router = Router();

router.get('/', authenticateJWT, getConversations);

export default router;
