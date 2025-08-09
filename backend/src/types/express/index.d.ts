// Não importa o modelo diretamente para evitar problemas de dependência circular

declare global {
  namespace Express {
    interface Request {
      user?: any; // JWT payload ou objeto User
      file?: Express.Multer.File; // arquivo único (upload.single)
      files?: Express.Multer.File[] | { [fieldname: string]: Express.Multer.File[] }; // múltiplos arquivos
    }
  }
}

export {};