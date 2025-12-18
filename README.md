# 📱 Task Manager - Aplicação Mobile Offline-First

[![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-14.x+-339933?logo=node.js)](https://nodejs.org)
[![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite)](https://www.sqlite.org)

Aplicação completa de gerenciamento de tarefas desenvolvida em Flutter com arquitetura **Offline-First**, sincronização automática e resolução de conflitos.

## 📋 Sobre o Projeto

Este projeto demonstra a implementação de uma aplicação mobile robusta que funciona perfeitamente mesmo sem conexão com a internet. Todas as operações são realizadas localmente e sincronizadas automaticamente quando a conexão é restaurada.

### ✨ Principais Características

- 📱 **100% Funcional Offline** - Todas as operações funcionam sem internet
- 🔄 **Sincronização Automática** - Dados sincronizam automaticamente quando conexão retorna
- ⚡ **Resolução de Conflitos LWW** - Last-Write-Wins para resolução automática
- 💾 **Persistência Local** - SQLite para armazenamento robusto
- 🎯 **Interface Intuitiva** - UI/UX otimizada para produtividade
- 🌐 **API REST** - Backend Node.js/Express completo

## 🏗️ Estrutura do Projeto

```
LAB_DAMD2/
├── task_manager/          # Aplicação Flutter
│   ├── lib/
│   │   ├── models/       # Modelos de dados
│   │   ├── services/     # Lógica de negócio
│   │   ├── screens/      # Interfaces
│   │   └── main.dart
│   └── README.md         # Documentação detalhada
│
├── backend/               # API REST
│   ├── server.js         # Servidor Express
│   ├── package.json
│   └── tasks.json        # Persistência
│
└── docs/                  # Documentação
    ├── GUIA_DEMONSTRACAO.md    # Roteiro de demonstração
    ├── SETUP_RAPIDO.md         # Setup rápido
    └── Offiline-First.md       # Especificações
```

## 🚀 Quick Start

### 1️⃣ Clonar Repositório

```bash
git clone https://github.com/GuCeolin/LAB_DAMD2.git
cd LAB_DAMD2
```

### 2️⃣ Instalar Dependências

**Backend:**
```bash
cd backend
npm install
```

**Frontend:**
```bash
cd task_manager
flutter pub get
```

### 3️⃣ Iniciar Backend

```bash
cd backend
node server.js
```

### 4️⃣ Executar App

```bash
cd task_manager
flutter run
```

## 📖 Documentação

- **[Task Manager README](task_manager/README.md)** - Documentação técnica completa
- **[Guia de Demonstração](GUIA_DEMONSTRACAO.md)** - Roteiro para apresentação
- **[Setup Rápido](SETUP_RAPIDO.md)** - Configuração e troubleshooting
- **[Checklist](CHECKLIST.md)** - Lista de implementações

## 🎯 Funcionalidades Implementadas

### ✅ CRUD de Tarefas
- [x] Criar tarefas
- [x] Listar tarefas
- [x] Editar tarefas
- [x] Deletar tarefas
- [x] Marcar como completa
- [x] Prioridades (Baixa, Média, Alta)
- [x] Filtros por status

### ✅ Offline-First
- [x] Persistência local com SQLite
- [x] Detector de conectividade
- [x] Fila de sincronização
- [x] Sincronização automática
- [x] Resolução de conflitos LWW
- [x] Indicador visual de status

### ✅ Backend
- [x] API REST completa
- [x] Endpoints CRUD
- [x] Persistência em arquivo
- [x] Suporte a CORS
- [x] Tratamento de erros

## 🛠️ Tecnologias

### Frontend
- **Flutter** 3.9.0+ - Framework mobile
- **sqflite** - Banco de dados SQLite
- **connectivity_plus** - Detector de rede
- **http** - Cliente HTTP
- **uuid** - Geração de IDs
- **intl** - Formatação

### Backend
- **Node.js** 14.x+ - Runtime
- **Express** 4.x - Framework web
- **body-parser** - Parser JSON
- **cors** - CORS middleware

## 🧪 Testando a Aplicação

### Modo Online
1. Iniciar backend
2. Executar app
3. Criar tarefas
4. Verificar sincronização

### Modo Offline
1. Ativar modo avião no dispositivo
2. Criar/editar tarefas
3. Observar operações funcionando
4. Desativar modo avião
5. Ver sincronização automática

## 📊 Arquitetura

```
┌─────────────────┐
│   Flutter UI    │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Services │
    └────┬────┘
         │
    ┌────┴─────┐
    │  SQLite  │─────┐
    └──────────┘     │
                     │
              ┌──────┴──────┐
              │ Sync Queue  │
              └──────┬──────┘
                     │
              ┌──────┴──────┐
              │  API Client │
              └──────┬──────┘
                     │
              ┌──────┴──────┐
              │   Backend   │
              │   Express   │
              └─────────────┘
```

## 🎓 Contexto Acadêmico

**Disciplina:** Desenvolvimento de Aplicativos Móveis e Dispositivos  
**Objetivo:** Demonstrar implementação de arquitetura Offline-First  
**Ano:** 2025

## 👥 Autores

Desenvolvido por alunos como projeto acadêmico.

## 📝 Licença

Este projeto é de uso educacional.

---

## 🔗 Links Úteis

- [Flutter Documentation](https://docs.flutter.dev/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Express.js Documentation](https://expressjs.com/)
- [Offline-First Pattern](https://offlinefirst.org/)

## 💡 Próximos Passos

- [ ] Implementar autenticação
- [ ] Adicionar testes unitários
- [ ] Implementar cache de imagens
- [ ] Suporte a múltiplos usuários
- [ ] Deploy em produção

---

**⭐ Se este projeto foi útil, considere dar uma estrela!**
