
// Não importa o modelo diretamente para evitar problemas de dependência circular

declare global {
  namespace Express {
    interface Request {
      user?: any; // JWT payload ou objeto User
    }
  }
}