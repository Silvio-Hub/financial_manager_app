# Guia da Lista de Transações com Cloud Firestore

## Funcionalidades Implementadas

### 1. Lista de Transações Responsiva
- **Tela**: `TransactionsListScreen`
- **Localização**: `lib/screens/transactions_list_screen.dart`
- **Características**:
  - Layout responsivo que se adapta a diferentes tamanhos de tela
  - Animações suaves para filtros e carregamento
  - Interface intuitiva com cards para cada transação

### 2. Filtros Avançados
- **Tipo de Transação**: Receita ou Despesa
- **Categoria**: Todas as categorias disponíveis (Alimentação, Transporte, etc.)
- **Período**: Seleção de data inicial e final
- **Valor**: Filtro por valor mínimo e máximo
- **Busca por Texto**: Pesquisa na descrição das transações

### 3. Scroll Infinito com Paginação
- **Carregamento Automático**: Novas transações são carregadas automaticamente ao rolar para baixo
- **Tamanho da Página**: 20 transações por vez
- **Indicador de Carregamento**: Mostra progresso durante o carregamento

### 4. Integração com Cloud Firestore

#### Estrutura de Dados no Firestore
```
users/{userId}/transactions/{transactionId}
```

#### Métodos Implementados

##### No `FirestoreService`:
- `addTransaction()`: Adiciona nova transação
- `updateTransaction()`: Atualiza transação existente
- `deleteTransaction()`: Remove transação
- `getAllTransactions()`: Busca todas as transações do usuário
- `getTransactionsWithFilters()`: Busca com filtros e paginação
- `getTransactionsStream()`: Stream em tempo real
- `syncLocalDataToFirestore()`: Sincroniza dados locais

##### No `FinancialProvider`:
- `loadTransactionsFromFirestore()`: Carrega do Firestore com fallback local
- `addTransactionWithSync()`: Adiciona com sincronização
- `updateTransactionWithSync()`: Atualiza com sincronização
- `removeTransactionWithSync()`: Remove com sincronização
- `loadTransactionsWithFiltersFromFirestore()`: Filtros com Firestore
- `forceSyncWithFirestore()`: Sincronização forçada

### 5. Sincronização Híbrida (Local + Firestore)

#### Estratégia de Fallback
1. **Usuário Autenticado**: Usa Firestore como fonte principal
2. **Usuário Não Autenticado**: Usa armazenamento local (SharedPreferences)
3. **Erro de Conexão**: Fallback automático para dados locais
4. **Sincronização**: Dados locais são sincronizados quando o usuário se autentica

#### Vantagens
- **Funciona Offline**: Dados locais garantem funcionamento sem internet
- **Sincronização Automática**: Dados são sincronizados automaticamente
- **Backup Local**: Dados são sempre salvos localmente como backup
- **Performance**: Carregamento rápido com cache local

### 6. Segurança do Firestore

#### Regras de Segurança (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/transactions/{transactionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Características de Segurança
- **Autenticação Obrigatória**: Apenas usuários autenticados podem acessar
- **Isolamento por Usuário**: Cada usuário só acessa suas próprias transações
- **Validação de Propriedade**: Verificação de que o usuário é o dono dos dados

## Como Usar

### 1. Acessar a Lista de Transações
- No Dashboard, clique no ícone de lista (📋) no AppBar
- Ou navegue diretamente para `TransactionsListScreen`

### 2. Aplicar Filtros
1. Clique no ícone de filtro no AppBar
2. Selecione os filtros desejados:
   - **Tipo**: Receita/Despesa
   - **Categoria**: Selecione uma categoria específica
   - **Período**: Escolha data inicial e final
   - **Valor**: Defina valor mínimo e máximo
3. Os filtros são aplicados automaticamente

### 3. Buscar Transações
- Digite na barra de pesquisa no topo da tela
- A busca é feita na descrição das transações
- Resultados são filtrados em tempo real

### 4. Carregar Mais Transações
- Role para baixo na lista
- Novas transações são carregadas automaticamente
- Indicador de carregamento aparece durante o processo

### 5. Ver Detalhes da Transação
- Toque em qualquer transação na lista
- Um bottom sheet aparece com todos os detalhes
- Inclui descrição, categoria, tipo, valor, data e observações

## Logs de Debug

Para monitorar a integração com Firestore, observe os logs que começam com "DEBUG:":

```
DEBUG: Usuário não autenticado, carregando dados locais
DEBUG: Carregando transações do Firestore...
DEBUG: 15 transações carregadas do Firestore
DEBUG: Transação sincronizada com Firestore
DEBUG: Sincronizando 10 transações locais com Firestore
```

## Tratamento de Erros

### Cenários Cobertos
1. **Usuário não autenticado**: Usa dados locais
2. **Erro de conexão**: Fallback para dados locais
3. **Erro de sincronização**: Mantém dados locais e exibe mensagem
4. **Dados corrompidos**: Validação e recuperação automática

### Mensagens de Erro
- "Erro ao carregar dados online": Problema de conexão com Firestore
- "Transação salva localmente. Erro de sincronização": Falha na sincronização
- "Usuário não autenticado para sincronização": Tentativa de sync sem auth

## Próximos Passos

1. **Implementar Edição de Transações**: Permitir editar transações existentes
2. **Adicionar Categorias Personalizadas**: Usuário pode criar suas próprias categorias
3. **Relatórios Avançados**: Gráficos e relatórios baseados nos filtros
4. **Exportação de Dados**: Exportar transações filtradas para CSV/PDF
5. **Notificações**: Alertas para metas de gastos e lembretes