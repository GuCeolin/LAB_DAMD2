# 📱 Guia de Demonstração - Aplicativo Offline-First

## ✅ STATUS DA IMPLEMENTAÇÃO: COMPLETO

Todos os componentes foram implementados com sucesso:
- ✅ Persistência Local (SQLite)
- ✅ Detector de Conectividade (connectivity_plus)
- ✅ Fila de Sincronização (sync_queue table)
- ✅ Resolução de Conflitos LWW (Last-Write-Wins)
- ✅ Backend API REST (Node.js/Express)

---

## 🚀 PREPARAÇÃO PARA DEMONSTRAÇÃO

### 1. Configurar o Endereço IP da API

**IMPORTANTE:** Você precisa usar o emulador Android ou dispositivo físico. A Web (Chrome) não suporta SQLite.

**Opção A: Usando Emulador Android (localhost funciona)**
- Mantenha: `http://10.0.2.2:3000` (IP especial do emulador)
- Arquivo: `lib/services/api_service.dart`, linha 8

**Opção B: Usando Dispositivo Físico Android**
- Seu IP da rede: `172.20.10.12` (WiFi EthernetLAN)
- Ou: `10.59.227.199` (Ethernet corporativa)
- Altere para: `http://172.20.10.12:3000`
- Celular e PC devem estar **na mesma rede WiFi**

### 2. Iniciar o Backend

```bash
cd backend
node server.js
```

Deve aparecer: `Server is running on http://localhost:3000`

### 3. Executar o Aplicativo

**Para Emulador Android:**
```bash
flutter emulators  # Ver emuladores disponíveis
flutter emulators --launch <nome_emulador>  # Iniciar emulador
flutter run -d <emulator_id>  # Rodar app
```

**Para Dispositivo Físico:**
```bash
flutter devices  # Ver dispositivos conectados
flutter run -d <device_id>  # Rodar no celular
```

---

## 🎬 ROTEIRO DA DEMONSTRAÇÃO (Siga EXATAMENTE)

### 📍 FASE 1: Prova de Vida Offline (5 min)

1. **Abrir o aplicativo** conectado à internet
   - ✅ Verificar indicador **VERDE** no topo (ONLINE)
   - ✅ Criar 1 tarefa de teste para garantir que está funcionando

2. **Ativar Modo Avião no celular**
   - ✅ Indicador muda para **VERMELHO/LARANJA** (OFFLINE)
   - ✅ Mostrar mensagem "Modo Offline - Dados serão sincronizados"

3. **Criar 2 novas tarefas offline:**
   - Tarefa 1: "Comprar pão" (prioridade: Baixa)
   - Tarefa 2: "Reunião às 15h" (prioridade: Alta)
   - ✅ Tarefas aparecem na lista
   - ✅ Cada tarefa mostra ícone de **nuvem cortada** (⚠️ pendente sync)

4. **Editar 1 tarefa existente offline:**
   - Marcar "Comprar pão" como completa
   - ✅ Mudança aparece imediatamente
   - ✅ Ícone de pendente ainda visível

---

### 📍 FASE 2: Persistência de Dados (2 min)

5. **Fechar o app COMPLETAMENTE**
   - Android: Botão Recentes → Arrastar app para fora (kill process)
   - OU: Configurações → Apps → Task Manager → Forçar parada

6. **Reabrir o aplicativo (ainda em Modo Avião)**
   - ✅ Todas as tarefas criadas offline **AINDA ESTÃO LÁ**
   - ✅ Edições foram mantidas
   - ✅ Indicador continua VERMELHO (offline)
   - ✅ Ícones de pendente permanecem

**EXPLICAÇÃO:** Isso prova que os dados foram salvos localmente no SQLite

---

### 📍 FASE 3: Sincronização Automática (3 min)

7. **Desativar Modo Avião**
   - ✅ Aplicativo detecta conexão automaticamente
   - ✅ Indicador muda para **VERDE** (ONLINE)
   - ✅ Mensagem: "Sincronizando dados..."

8. **Observar sincronização automática:**
   - ✅ Ícones de nuvem cortada mudam para **check verde** (✓ sincronizado)
   - ✅ SnackBar aparece: "Sincronização concluída!"
   - ✅ Todas as 2 tarefas criadas foram enviadas ao servidor
   - ✅ Edição também foi sincronizada

9. **PROVA: Verificar no servidor**
   - Abrir navegador: `http://localhost:3000/tasks`
   - ✅ JSON mostra as tarefas que foram criadas offline
   - OU usar Postman: GET `http://localhost:3000/tasks`

---

### 📍 FASE 4: Resolução de Conflitos LWW (5 min)

10. **Preparar conflito simultâneo:**

**No Postman (ou navegador):**
```json
PUT http://localhost:3000/tasks/<ID_DA_TAREFA>
Content-Type: application/json

{
  "id": "<ID_DA_TAREFA>",
  "title": "Comprar pão INTEGRAL (EDITADO NO SERVIDOR)",
  "description": "Versão do servidor",
  "completed": false,
  "priority": "high",
  "createdAt": "2025-12-15T10:00:00.000Z",
  "updatedAt": "2025-12-15T10:05:00.000Z"  // ← Timestamp mais RECENTE
}
```

**No App (ainda online):**
- Editar a MESMA tarefa
- Mudar para: "Comprar pão e leite (EDITADO NO APP)"
- updatedAt será definido como agora (mais antigo que o servidor)

11. **Ativar Modo Avião novamente**
    - Fazer a edição no app offline
    - Desativar Modo Avião

12. **Observar resolução de conflito:**
    - ✅ App tenta sincronizar
    - ✅ Servidor rejeita (409 Conflict) porque tem versão mais recente
    - ✅ App recebe versão do servidor
    - ✅ **Versão do SERVIDOR prevalece** (Last-Write-Wins)
    - ✅ App mostra: "Comprar pão INTEGRAL (EDITADO NO SERVIDOR)"

**EXPLICAÇÃO:** Last-Write-Wins compara timestamps. Versão mais recente sempre vence.

---

## 🧪 CENÁRIOS DE TESTE EXTRAS

### Teste 1: Múltiplas Operações Offline
1. Modo Avião ON
2. Criar 3 tarefas
3. Editar 2 tarefas
4. Deletar 1 tarefa
5. Modo Avião OFF
6. ✅ Todas operações sincronizadas na ordem correta

### Teste 2: Perda de Conexão Durante Uso
1. App rodando online
2. Criar tarefa (sincroniza)
3. Tirar WiFi do celular (simular queda)
4. Tentar criar outra tarefa
5. ✅ Tarefa salva localmente
6. Reativar WiFi
7. ✅ Sincronização automática

### Teste 3: Conflito com Delete
1. Criar tarefa online
2. Modo Avião ON (app)
3. Deletar no servidor (Postman)
4. Editar no app offline
5. Modo Avião OFF
6. ✅ Tarefa não existe mais (servidor vence)

---

## 📊 CHECKLIST DE PONTOS (25 pts)

| Requisito | Status | Pontos |
|-----------|--------|--------|
| SQLite persistência local | ✅ | 6 pts |
| Detector conectividade visual | ✅ | 4 pts |
| Fila de sincronização (sync_queue) | ✅ | 6 pts |
| Sincronização automática | ✅ | 5 pts |
| Resolução conflitos LWW | ✅ | 4 pts |
| **TOTAL** | ✅ | **25 pts** |

---

## 🐛 TROUBLESHOOTING

### Erro: "Failed to connect to server"
- ✅ Backend está rodando? (`node server.js`)
- ✅ IP correto no `api_service.dart`?
- ✅ Celular e PC na mesma rede WiFi?
- ✅ Firewall bloqueando porta 3000?

### Erro: "Unable to locate Android SDK"
- ✅ Instalar Android Studio
- ✅ Configurar Android SDK
- ✅ Criar AVD (emulador)

### App não sincroniza automaticamente
- ✅ Verificar logs: `flutter logs`
- ✅ Conectividade realmente voltou?
- ✅ Verificar tabela sync_queue tem itens

### Conflito não resolvido corretamente
- ✅ Timestamps estão corretos?
- ✅ Servidor retornando 409?
- ✅ App recebendo serverTask do servidor?

---

## 📝 NOTAS IMPORTANTES

1. **NÃO use Chrome/Web** - SQLite não funciona no navegador
2. **Backend deve estar rodando** antes de testar sincronização
3. **Timestamps são UTC** - não altere fuso horário durante testes
4. **Fila é FIFO** - operações sincronizam na ordem que foram criadas
5. **LWW compara updatedAt** - não createdAt

---

## 🎓 EXPLICAÇÃO TÉCNICA PARA O PROFESSOR

### Arquitetura Offline-First

```
[UI] → [Database Service] → [SQLite Local]
  ↓            ↓
[Connectivity] ↓
Service     [Sync Queue]
  ↓            ↓
[Sync Service] → [API Service] → [Backend REST API]
```

### Fluxo de Criação de Tarefa Offline:

1. Usuário cria tarefa na UI
2. `DatabaseService.create()` salva no SQLite
3. `DatabaseService.createSyncItem()` adiciona à fila de sync
4. Task aparece na UI com ícone de pendente
5. Quando conexão retorna:
   - `ConnectivityService` notifica `SyncService`
   - `SyncService` processa fila FIFO
   - Cada item é enviado via `ApiService`
   - Sucesso → marca item como sincronizado
   - Falha → item permanece na fila para retry

### Algoritmo LWW (Last-Write-Wins):

```dart
if (serverTask.updatedAt > localTask.updatedAt) {
  // Servidor vence - sobrescrever local
  db.updateWithoutSync(serverTask);
} else if (localTask.updatedAt > serverTask.updatedAt) {
  // Cliente vence - enviar para servidor
  api.updateTask(localTask);
}
```

---

## ✅ PRONTO PARA DEMONSTRAÇÃO!

Siga o roteiro exatamente como descrito e você terá uma demonstração perfeita do sistema Offline-First com todos os 25 pontos garantidos! 🎉
