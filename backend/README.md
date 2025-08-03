# Roadmap Backend TalkTo

## 1. Configuração inicial
- Conectar ao MongoDB Atlas (já feito)
- Criar estrutura de pastas: `controllers`, `models`, `routes`, `middlewares`

## 2. Modelos (Models)
- **User:** nome, email, senha (hash), foto, etc
- **Message:** de, para, conteúdo, tipo (texto/figurinha), timestamp

## 3. Rotas de autenticação
- `POST /auth/register`: cadastro de usuário
- `POST /auth/login`: login e geração de token JWT

## 4. Middlewares
- Autenticação JWT para proteger rotas

## 5. Rotas de usuários
- `GET /users`: listar todos os usuários (exceto o logado)
- `GET /users/:id`: buscar dados de um usuário

## 6. Rotas de chat/mensagens
- `GET /chats/:userId`: histórico de conversa entre usuários
- `POST /messages`: enviar mensagem (texto ou figurinha)

## 7. Upload de imagem
- Rota para upload de foto de perfil (usando multer ou serviço externo)

## 8. Testes
- Testar todas as rotas e integrações

## 9. Documentação
- Documentar endpoints e exemplos de uso
