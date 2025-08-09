import { Router } from 'express';
import { authenticateJWT } from '../middlewares/auth.middleware';
import { upload } from '../config/multer';
import { uploadPhoto } from '../controllers/upload.controller';

const router = Router();

router.post('/:id/photo', authenticateJWT, upload.single('photo'), uploadPhoto);

export default router;
