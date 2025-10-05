# Guia de Configuração do Firebase Storage

## 🚨 Problema Identificado

O erro `StorageException -13040` com código HTTP 404 indica que o **Firebase Storage não está habilitado** no console do Firebase.

### Erro Específico:
```
E/StorageException: { "error": { "code": 404, "message": "Not Found." }}
E/StorageException: The server has terminated the upload session
E/StorageException: StorageException has occurred.
E/StorageException: The operation was cancelled.
E/StorageException: Code: -13040 HttpResult: 0
```

## ✅ Melhorias Implementadas

### 1. **Verificação de Conectividade**
- Método `checkStorageConnection()` que testa a conectividade antes do upload
- Detecta automaticamente se o Storage está configurado

### 2. **Logs Detalhados**
- Logs completos do processo de upload para facilitar diagnóstico
- Informações sobre tamanho do arquivo e caminho de upload

### 3. **Mensagens de Erro Melhoradas**
- Mensagens específicas para cada tipo de erro
- Instruções claras sobre como resolver cada problema

## 🔧 Solução Necessária

### Passo 1: Habilitar Firebase Storage
1. Acesse o [Console do Firebase](https://console.firebase.google.com)
2. Selecione o projeto `financeiro-9cb44`
3. No menu lateral, clique em **"Storage"**
4. Clique em **"Começar"** ou **"Get Started"**
5. Escolha o modo de teste (temporário) ou produção
6. Selecione a localização do bucket (recomendado: `us-central1`)

### Passo 2: Configurar Regras de Segurança
1. No console do Storage, vá para a aba **"Rules"**
2. Substitua as regras padrão pelo conteúdo do arquivo `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Permite acesso apenas a usuários autenticados
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    
    // Regra específica para recibos
    match /receipts/{userId}/{transactionId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Passo 3: Verificar Configuração
1. Certifique-se de que o bucket está ativo
2. Teste o upload de um arquivo pequeno
3. Verifique se as regras estão aplicadas

## 📱 Como Testar

1. **Faça login no aplicativo**
2. **Vá para adicionar uma transação**
3. **Tente fazer upload de um recibo**
4. **Observe os logs no terminal** para diagnóstico detalhado

### Logs Esperados (Sucesso):
```
Verificando conectividade com Firebase Storage...
Iniciando upload do recibo...
Caminho do arquivo: receipts/[userId]/[transactionId]/[timestamp]_[filename]
Upload de arquivo File ([size] bytes)
Aguardando conclusão do upload...
Upload concluído, obtendo URL de download...
URL de download obtida: [url]
```

### Logs de Erro (Storage não habilitado):
```
Verificando conectividade com Firebase Storage...
Erro na verificação do Storage: [erro]
Firebase Storage não está configurado ou acessível.
Verifique se:
1. O Firebase Storage está habilitado no console
2. As regras de segurança estão configuradas
3. Você tem conexão com a internet
```

## 🔍 Códigos de Erro Comuns

| Código | Descrição | Solução |
|--------|-----------|---------|
| `storage/bucket-not-found` | Storage não habilitado | Habilitar Storage no console |
| `storage/unauthorized` | Sem permissão | Verificar regras de segurança |
| `storage/unauthenticated` | Usuário não logado | Fazer login novamente |
| `storage/quota-exceeded` | Cota excedida | Verificar limites do plano |

## 📞 Próximos Passos

1. **Habilite o Firebase Storage** seguindo o Passo 1
2. **Configure as regras** seguindo o Passo 2
3. **Teste o upload** no aplicativo
4. **Verifique os logs** para confirmar funcionamento

## 🆘 Se o Problema Persistir

1. Verifique se está usando o projeto correto (`financeiro-9cb44`)
2. Confirme se o usuário está autenticado
3. Teste com um arquivo pequeno (< 1MB)
4. Verifique a conexão com a internet
5. Consulte os logs detalhados no terminal

---

**Nota**: As melhorias implementadas no código fornecerão mensagens de erro mais claras e logs detalhados para facilitar o diagnóstico de problemas futuros.