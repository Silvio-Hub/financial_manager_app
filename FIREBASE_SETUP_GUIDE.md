# Guia de Configuração do Firebase Authentication

## Problema Identificado
O erro "notfound" que você está enfrentando ao criar uma conta está relacionado ao erro `CONFIGURATION_NOT_FOUND` do Firebase. Isso indica que a autenticação por email/senha não está habilitada no console do Firebase.

## Solução: Configurar Firebase Authentication

### Passo 1: Acessar o Console do Firebase
1. Acesse [https://console.firebase.google.com](https://console.firebase.google.com)
2. Faça login com sua conta Google
3. Selecione o projeto `financeiro-9cb44`

### Passo 2: Habilitar Authentication
1. No menu lateral esquerdo, clique em **"Authentication"**
2. Se for a primeira vez, clique em **"Get started"**
3. Vá para a aba **"Sign-in method"**

### Passo 3: Habilitar Email/Password
1. Na lista de provedores, encontre **"Email/Password"**
2. Clique no provedor **"Email/Password"**
3. **Habilite** a primeira opção (Email/Password)
4. Opcionalmente, você pode habilitar também **"Email link (passwordless sign-in)"**
5. Clique em **"Save"**

### Passo 4: Configurar Domínios Autorizados (se necessário)
1. Ainda na aba **"Sign-in method"**, role para baixo até **"Authorized domains"**
2. Certifique-se de que `localhost` está na lista (para desenvolvimento)
3. Se não estiver, clique em **"Add domain"** e adicione `localhost`

### Passo 5: Verificar Configurações de Segurança
1. Vá para a aba **"Settings"** (engrenagem no canto superior direito)
2. Selecione **"Project settings"**
3. Na aba **"General"**, verifique se as configurações do projeto estão corretas

## Verificação da Correção

Após seguir esses passos:

1. **Reinicie o aplicativo** (pare e execute `flutter run` novamente)
2. **Teste a criação de conta** novamente
3. **Verifique os logs** - agora você deve ver mensagens mais claras sobre erros

## Melhorias Implementadas no Código

O código foi atualizado para:
- Detectar especificamente erros de configuração do Firebase
- Fornecer mensagens de erro mais claras
- Incluir logs detalhados para debug

## Códigos de Erro Comuns

- `configuration-not-found`: Autenticação não configurada no console
- `operation-not-allowed`: Método de autenticação não habilitado
- `email-already-in-use`: Email já cadastrado
- `weak-password`: Senha muito fraca (menos de 6 caracteres)
- `invalid-email`: Formato de email inválido

## Próximos Passos

1. Configure o Firebase Authentication conforme as instruções acima
2. Teste a criação de conta novamente
3. Se ainda houver problemas, verifique os logs do aplicativo para erros específicos

## Contato para Suporte

Se o problema persistir após seguir este guia, verifique:
- Se o projeto Firebase está ativo
- Se as chaves de API estão corretas
- Se há limitações de cota no projeto Firebase