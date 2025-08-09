# TalkTo

Aplicativo de mensagens (MVP) com frontend em Flutter e backend em Node.js/Express + MongoDB Atlas.

## Visão Geral
O TalkTo permite cadastro de usuários com foto de perfil, autenticação JWT, listagem de contatos, troca de mensagens (texto / figurinha) e upload de imagem. Este repositório contém:
- Backend: `/backend`
- Frontend (Flutter): `/frontend`

## Stack
Backend:
- Node.js / Express 5
- TypeScript
- MongoDB Atlas (Mongoose)
- JWT (autenticação)
- Multer (upload de imagem)

Frontend:
- Flutter (Material Design)
- (Planejado) Dio ou http para consumo de API
- (Planejado) Gerenciamento de estado (Provider / Riverpod / Bloc)

## Estrutura do Repositório
```
/ backend
  /src
    /controllers
    /routes
    /models
    /middlewares
    /config
    index.ts
  .env (não comitar)
/ frontend
  /lib
    main.dart
    /screens
    /widgets
    /services (futuro)
/uploads (gerado em runtime para fotos)
```

## Funcionalidades (Status)
| Funcionalidade | Status |
| -------------- | ------ |
| Cadastro usuário | OK |
| Login + JWT | OK |
| Listar usuários | OK |
| Buscar usuário por ID | OK |
| Histórico de mensagens | Em desenvolvimento |
| Enviar mensagem | Em desenvolvimento |
| Upload foto perfil | Em desenvolvimento (rota criada) |
| Persistência token no app | Pendente |
| Chat em tempo real (WebSocket) | Futuro |
| Figurinhas | Futuro |

## Backend
### Instalação
```bash
cd backend
npm install
```
### Execução (dev)
```bash
npm run dev
```
### Variáveis de Ambiente (`backend/.env`)
```
PORT=3210
MONGODB_URI=YOUR_MONGODB_ATLAS_URI
JWT_SECRET=SUA_CHAVE_SECRETA_FORTE
```
### Endpoints (Resumo)
Auth:
- POST /auth/register
- POST /auth/login

Usuários:
- GET /users (JWT) – lista todos exceto o logado
- GET /users/:id (JWT)

Mensagens / Chat:
- GET /chats/:userId (JWT) (planejado)
- POST /messages (JWT) (planejado)

Upload:
- POST /upload/:id/photo (JWT) multipart (campo: photo)

### Modelo User
```
name, email, password(hash), phone, photoURL
```
### Modelo Message
```
from, to, content, type(text|sticker), timestamp
```

## Frontend
### Instalação
```bash
cd frontend
flutter pub get
```
### Rodar
```bash
flutter run
```
Especificar dispositivo:
```bash
flutter run -d linux
flutter run -d chrome
```
### Integração com Backend
Configurar base URL (ex: constante ou via env build):
```
http://localhost:3210
```
Enviar token no header:
```
Authorization: Bearer <TOKEN>
```
### Telas Atuais
- Splash
- Register
- Login
- Home (contatos - mock)
- Chat (básica)
- Profile

## Fluxo de Autenticação
1. Usuário registra ou faz login.
2. Backend retorna token JWT.
3. Frontend salva token localmente (implementar).
4. Cada requisição protegida envia o header Authorization.

## Upload de Foto (Testar via curl)
```bash
curl -X POST http://localhost:3210/upload/ID_DO_USUARIO/photo \
  -H "Authorization: Bearer TOKEN" \
  -F "photo=@/caminho/arquivo.jpg"
```
Resposta esperada:
```json
{ "message": "Foto atualizada!", "user": { "id": "...", "photoURL": "/uploads/arquivo.ext" } }
```

## Roadmap Próximo
Backend:
- Implementar GET /chats/:userId
- Implementar POST /messages
- Normalizar resposta de erros
- Adicionar paginação de mensagens
- Adicionar WebSocket (Socket.IO)

Frontend:
- Consumir lista real de usuários
- Persistir token (shared_preferences)
- Tela de edição de perfil + upload
- Estado global (Provider / Riverpod)
- Indicadores de envio / leitura

Infra / Geral:
- Scripts de build
- Docker (opcional futuro)
- Documentação de API (Swagger ou Redoc)

## Boas Práticas Adotadas
- Separação de camadas (controllers / routes / models)
- Uso de JWT para autenticação stateless
- Hash de senha (bcryptjs)
- Tipagem com TypeScript

## Contribuição
1. Criar branch: `feature/nome`  
2. Commits claros (mensagens descritivas)  
3. Abrir Pull Request para `main`

## Licença
Projeto educacional / interno (definir futuramente).

---
Mantido por: Otavio Emanoel
