# TalkTo Frontend (Flutter)

Aplicativo de mensagens instantâneas (MVP) desenvolvido em Flutter, consumindo o backend Node.js/Express + MongoDB.

## Sumário
- [Stack](#stack)
- [Recursos Implementados](#recursos-implementados)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Configuração e Execução](#configuração-e-execução)
- [Ambiente / Integração com Backend](#ambiente--integração-com-backend)
- [Navegação](#navegação)
- [Fluxo de Autenticação](#fluxo-de-autenticação)
- [Gerenciamento de Estado](#gerenciamento-de-estado)
- [Chamadas HTTP](#chamadas-http)
- [Estilos e Assets](#estilos-e-assets)
- [Boas Práticas](#boas-práticas)
- [Próximos Passos](#próximos-passos)

## Stack
- Flutter (stable)
- Dart
- Material Design 3 (customizações próprias)
- HTTP (pacote http ou dio – a definir)
- Armazenamento local: `shared_preferences` (para token JWT)

## Recursos Implementados
- Splash Screen
- Cadastro de usuário (UI)
- Login (UI) + consumo de API (em progresso)
- Lista de contatos (mock / integração futura)
- Tela de chat básica
- Tela de perfil

## Estrutura de Pastas
```
lib/
  main.dart                -> Ponto de entrada, rotas
  screens/
    splash/
    login/
    register/
    home/
    chat/
    profile/
  widgets/                 -> Componentes reutilizáveis (botões, inputs, etc)
  services/                -> Serviços (API, auth, storage)
  models/                  -> Modelos de dados (User, Message)
  theme/                   -> Cores, tipografia, estilos
  utils/                   -> Helpers, formatadores
  assets/ (em pubspec.yaml)
```

## Configuração e Execução
1. Instalar dependências:
```
flutter pub get
```
2. Rodar no dispositivo/emulador disponível:
```
flutter run
```
3. Especificar plataforma:
```
flutter run -d linux
flutter run -d chrome
flutter run -d emulator-5554
```
4. Gerar build (exemplos):
```
flutter build apk --release
flutter build web
```

## Ambiente / Integração com Backend
Crie um arquivo `.env` (usando o pacote `flutter_dotenv`, se adotado) para armazenar a URL base:
```
API_BASE_URL=http://localhost:3210
```
Exemplo de inicialização (pseudo):
```dart
// await dotenv.load(fileName: '.env');
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3210');
```

Endpoints relevantes (backend):
- POST /auth/register
- POST /auth/login (retorna token JWT)
- GET /users (protegido)
- GET /users/:id (protegido)
- GET /chats/:userId (protegido)
- POST /messages (protegido)
- POST /upload/:id/photo (protegido)

## Navegação
Utiliza rotas nomeadas definidas em `main.dart`. Exemplo de push para chat:
```dart
Navigator.pushNamed(context, '/chat', arguments: ChatArgs(userId: '...'));
```

## Fluxo de Autenticação
1. Usuário faz login.
2. Recebe token JWT.
3. Token salvo localmente (shared_preferences).
4. Requests autenticadas enviam header:
```
Authorization: Bearer <token>
```
5. Logout remove o token.

## Gerenciamento de Estado
Ainda simples (setState). Próximos candidatos:
- Riverpod
- Provider
- Bloc / Cubit

## Chamadas HTTP
Exemplo com pacote http (placeholder):
```dart
final resp = await http.get(
  Uri.parse('$apiBaseUrl/users'),
  headers: { 'Authorization': 'Bearer $token' },
);
```
Sugestão: abstrair em `services/api_service.dart`.

## Estilos e Assets
- Adicionar imagens em `assets/images/`
- Registrar em `pubspec.yaml`:
```
assets:
  - assets/images/
  - assets/icon.png
```
- Centralizar cores em `theme/app_colors.dart`.

## Boas Práticas
- Evitar lógica de rede dentro de widgets.
- Separar camadas: UI, serviço, modelo.
- Tratar erros de rede com feedback visual (SnackBar / Dialog).
- Colocar loading states (CircularProgressIndicator).

## Próximos Passos
- Integrar telas com backend (login real + lista de usuários).
- Implementar persistência do token.
- WebSocket / Socket.IO para mensagens em tempo real.
- Upload de imagem do perfil direto pelo app.
- Melhorar UI/UX (animações, dark mode).
- Testes unitários e widget tests.

## Contribuição
1. Criar branch feature/nome
2. Commitar mudanças claras
3. Abrir PR para `main`

## Licença
Projeto educacional / interno (definir se será aberto futuramente).

---
Qualquer dúvida: ajustar este README conforme o projeto evoluir.
