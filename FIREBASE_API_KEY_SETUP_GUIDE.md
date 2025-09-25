# Guia de Configuração da API Key do Firebase

## 🚨 Problema Identificado

Os dados não estão sendo exibidos no banco de dados do Firebase porque a **API key está inválida**. 

### Erro Atual:
```
API key not valid. Please pass a valid API key.
```

### Causa:
As API keys no projeto são placeholders (exemplos) e não são chaves reais válidas do Firebase.

## 🔧 Solução Completa

### Passo 1: Acessar o Console do Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Faça login com sua conta Google
3. Selecione o projeto `financialmanager-b0098`

### Passo 2: Verificar/Criar Aplicativos

1. No painel do projeto, clique em **"Configurações do projeto"** (ícone de engrenagem)
2. Vá para a aba **"Geral"**
3. Na seção **"Seus aplicativos"**, verifique se existem:
   - **Aplicativo Android**: `com.example.financial_manager`
   - **Aplicativo Web**: Para a versão web

### Passo 3: Obter Arquivos de Configuração

#### Para Android:
1. Clique no aplicativo Android
2. Baixe o arquivo `google-services.json`
3. Substitua o arquivo em: `android/app/google-services.json`

#### Para Web/Outras Plataformas:
1. Clique no aplicativo Web
2. Copie a configuração do Firebase
3. Atualize o arquivo `lib/firebase_options.dart`

### Passo 4: Atualizar Configurações

#### Arquivo `android/app/google-services.json`:
```json
{
  "project_info": {
    "project_number": "210776833063",
    "project_id": "financialmanager-b0098",
    "storage_bucket": "financialmanager-b0098.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:210776833063:android:cc5dae2442af3955682202",
        "android_client_info": {
          "package_name": "com.example.financial_manager"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "SUA_API_KEY_REAL_AQUI"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

#### Arquivo `lib/firebase_options.dart`:
```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUA_API_KEY_WEB_AQUI',
    appId: '1:210776833063:web:ae4b2cb32e97c84c682202',
    messagingSenderId: '210776833063',
    projectId: 'financialmanager-b0098',
    authDomain: 'financialmanager-b0098.firebaseapp.com',
    storageBucket: 'financialmanager-b0098.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SUA_API_KEY_ANDROID_AQUI',
    appId: '1:210776833063:android:cc5dae2442af3955682202',
    messagingSenderId: '210776833063',
    projectId: 'financialmanager-b0098',
    storageBucket: 'financialmanager-b0098.appspot.com',
  );

  // ... outras plataformas
}
```

### Passo 5: Habilitar Serviços do Firebase

1. **Firestore Database**:
   - Vá para "Firestore Database"
   - Clique em "Criar banco de dados"
   - Escolha "Iniciar no modo de teste" (temporariamente)

2. **Firebase Storage**:
   - Vá para "Storage"
   - Clique em "Começar"
   - Configure as regras de segurança

3. **Authentication**:
   - Vá para "Authentication"
   - Configure os métodos de login desejados

### Passo 6: Configurar Regras de Segurança

#### Firestore Rules (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/transactions/{transactionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

#### Storage Rules (`storage.rules`):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /receipts/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Passo 7: Aplicar as Regras

1. No terminal, execute:
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

### Passo 8: Testar a Aplicação

1. Reinicie o aplicativo Flutter:
```bash
flutter clean
flutter pub get
flutter run
```

2. Verifique os logs para confirmar que não há mais erros de API key

## 🔍 Verificação de Problemas

### Logs Esperados (Sucesso):
```
I/flutter: DEBUG: Carregando transações do Firestore...
I/flutter: DEBUG: 0 transações carregadas do Firestore
```

### Logs de Erro (Problema):
```
W/Firestore: API key not valid. Please pass a valid API key.
W/Firestore: Permission denied: Consumer 'api_key:...' has been suspended.
```

## 📋 Checklist de Verificação

- [ ] Projeto Firebase criado e configurado
- [ ] Aplicativo Android registrado no Firebase
- [ ] Arquivo `google-services.json` baixado e atualizado
- [ ] API keys reais configuradas em `firebase_options.dart`
- [ ] Firestore Database habilitado
- [ ] Firebase Storage habilitado
- [ ] Authentication configurado
- [ ] Regras de segurança aplicadas
- [ ] Aplicativo reiniciado e testado

## 🆘 Problemas Comuns

### 1. "Project not found"
- Verifique se o `projectId` está correto
- Confirme que o projeto existe no Firebase Console

### 2. "Permission denied"
- Verifique as regras de segurança
- Confirme que o usuário está autenticado

### 3. "API key not valid"
- Baixe novamente os arquivos de configuração
- Verifique se as API keys são reais (não placeholders)

### 4. "Storage bucket not found"
- Habilite o Firebase Storage no console
- Verifique se o `storageBucket` está correto

## 📞 Próximos Passos

Após seguir este guia:

1. **Teste o login/cadastro** para verificar a autenticação
2. **Teste a criação de transações** para verificar o Firestore
3. **Teste o upload de recibos** para verificar o Storage
4. **Monitore os logs** para identificar outros possíveis problemas

## 🔗 Links Úteis

- [Firebase Console](https://console.firebase.google.com/)
- [Documentação Flutter Firebase](https://firebase.flutter.dev/)
- [Configuração do FlutterFire](https://firebase.flutter.dev/docs/overview)