# 📱 Task Manager - Offline-First Mobile App

Um aplicativo Flutter completo de gerenciamento de tarefas com suporte **Offline-First**, sincronização automática e resolução de conflitos LWW (Last-Write-Wins).

## 🎯 Funcionalidades

### ✅ Gerenciamento de Tarefas
- Criar, editar e excluir tarefas
- Marcar tarefas como completas
- Definir prioridades (Baixa, Média, Alta)
- Adicionar descrições
- Filtrar por status (Todas, Pendentes, Completas)
- Contador de tarefas em tempo real

### 🌐 Offline-First
- **Persistência Local:** SQLite para armazenamento offline
- **Fila de Sincronização:** Operações offline enfileiradas automaticamente
- **Indicador Visual:** Status de conexão (Online/Offline) em tempo real
- **Sincronização Automática:** Dados sincronizam quando conexão retorna
- **Resolução de Conflitos LWW:** Versão mais recente sempre prevalece

## 🏗️ Arquitetura

```
lib/
├── models/
│   ├── task.dart              # Modelo de dados da tarefa
│   └── sync_queue_item.dart   # Modelo da fila de sincronização
├── services/
│   ├── database_service.dart      # Gerenciamento SQLite
│   ├── api_service.dart           # Comunicação com backend
│   ├── sync_service.dart          # Lógica de sincronização
│   └── connectivity_service.dart  # Detector de conectividade
├── screens/
│   └── task_list_screen.dart  # Interface principal
└── main.dart                  # Ponto de entrada

backend/
├── server.js          # API REST Node.js/Express
├── package.json       # Dependências do backend
└── tasks.json         # Armazenamento de dados
```

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK (>= 3.9.0)
- Node.js (>= 14.x)
- Android Studio (para emulador) OU dispositivo físico
- VS Code com extensão Flutter (opcional)

### 1. Instalar Dependências

**Frontend (Flutter):**
```bash
cd task_manager
flutter pub get
```

**Backend (Node.js):**
```bash
cd backend
npm install
```

### 2. Iniciar Backend

```bash
cd backend
node server.js
```

O servidor estará rodando em `http://localhost:3000`

### 3. Executar App

**Emulador Android:**
```bash
flutter run -d emulator-5554
```

**Dispositivo Físico:**
```bash
flutter devices  # Ver dispositivos disponíveis
flutter run -d <device-id>
```

## 📚 Documentação Completa

- **[GUIA_DEMONSTRACAO.md](../GUIA_DEMONSTRACAO.md)** - Roteiro completo para demonstração em sala
- **[SETUP_RAPIDO.md](../SETUP_RAPIDO.md)** - Configuração rápida e troubleshooting
- **[Offiline-First.md](../Offiline-First.md)** - Especificação dos requisitos

## 🧪 Tecnologias Utilizadas

### Frontend
- **Flutter** - Framework mobile multiplataforma
- **SQLite** (`sqflite`) - Banco de dados local
- **connectivity_plus** - Detector de conectividade
- **http** - Cliente HTTP
- **uuid** - Geração de IDs únicos
- **intl** - Formatação de datas

### Backend
- **Node.js** - Runtime JavaScript
- **Express** - Framework web
- **body-parser** - Parser de JSON
- **cors** - Cross-Origin Resource Sharing

## 📦 Estrutura do Banco de Dados

### Tabela `tasks`
```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  completed INTEGER NOT NULL,
  priority TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### Tabela `sync_queue`
```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  entityId TEXT NOT NULL,
  action TEXT NOT NULL,        -- 'create', 'update', 'delete'
  data TEXT,                    -- JSON da task
  timestamp TEXT NOT NULL,
  isSynced INTEGER NOT NULL     -- 0 = pendente, 1 = sincronizado
)
```

## 🔄 Fluxo de Sincronização

1. **Operação Offline:**
   - Usuário cria/edita/deleta tarefa
   - Salva no SQLite local
   - Adiciona à `sync_queue`

2. **Conexão Retorna:**
   - `ConnectivityService` detecta rede
   - `SyncService` processa fila FIFO
   - Envia operações via `ApiService`

3. **Resolução de Conflitos:**
   - Compara `updatedAt` (timestamps)
   - Versão mais recente vence (LWW)
   - Atualiza local se servidor mais recente

## 🧪 Testes e Demonstração

### Testar Modo Offline

1. **Iniciar com Conexão:**
   - Backend rodando
   - App conectado (indicador verde "Online")
   - Criar algumas tarefas

2. **Simular Offline:**
   - **Emulador:** Ativar modo avião (arraste tela de cima ou use painel lateral)
   - **Dispositivo:** Ativar modo avião
   - Observar indicador mudar para "Offline" (vermelho)

3. **Operações Offline:**
   - Criar novas tarefas
   - Editar tarefas existentes
   - Marcar como completas
   - Deletar tarefas
   - Todas operações funcionam normalmente!

4. **Restaurar Conexão:**
   - Desativar modo avião
   - Observar sincronização automática
   - Verificar que todas operações foram enviadas ao backend

### Testar Resolução de Conflitos

1. Editar mesma tarefa no app (offline)
2. Editar mesma tarefa diretamente no backend via API
3. Restaurar conexão
4. Versão mais recente (timestamp) prevalece

## 🔧 Troubleshooting

### Erro de Conexão com Backend

**Emulador Android:**
- Use `http://10.0.2.2:3000` (IP especial do emulador)
- Editar em `lib/services/api_service.dart`

**Dispositivo Físico:**
1. Descobrir IP do seu PC:
   ```bash
   # Windows
   ipconfig
   # Procurar por IPv4 Address
   ```
2. Usar `http://<SEU_IP>:3000`
3. PC e celular na mesma rede WiFi

### Banco de Dados Corrompido
```bash
flutter clean
flutter pub get
flutter run
```

### Dependências Desatualizadas
```bash
flutter pub upgrade
```

## 📱 Configuração Importante

**⚠️ Configurar IP da API antes de executar:**

Arquivo: `lib/services/api_service.dart`
```dart
// Emulador Android
static const String baseUrl = 'http://10.0.2.2:3000';

// Dispositivo Físico (substituir pelo seu IP)
static const String baseUrl = 'http://192.168.1.100:3000';
```

## 🎓 Créditos

Desenvolvido como projeto acadêmico para demonstração de arquitetura Offline-First em aplicações móveis.

**Disciplina:** Desenvolvimento de Aplicativos Móveis e Dispositivos  
**Ano:** 2025

## 📄 Licença

Este projeto é de uso educacional.
