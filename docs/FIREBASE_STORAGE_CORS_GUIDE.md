# Configurar CORS para Firebase Storage (Flutter Web)

Este guia resolve erros de CORS ao enviar arquivos para o Firebase Storage a partir do Flutter Web (por exemplo: "blocked by CORS policy: preflight request doesn't pass access control check").

## Quando é necessário
- Ao acessar `https://firebasestorage.googleapis.com/...` a partir de `http://localhost:<porta>` ou de um domínio web próprio.
- Uploads que usam `PUT`/`POST` (como o SDK) podem exigir CORS no bucket do Google Cloud Storage associado ao Firebase Storage.

## Passo 1 — Criar arquivo `cors.json`

Crie um arquivo `cors.json` com a configuração apropriada. Para desenvolvimento local rápido, você pode usar uma configuração permissiva (recomendado apenas para dev):

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT"],
    "responseHeader": ["*"],
    "maxAgeSeconds": 3600
  }
]
```

Para produção, restrinja os `origin` ao(s) seu(s) domínio(s):

```json
[
  {
    "origin": [
      "https://financeiro-9cb44.web.app",
      "https://financeiro-9cb44.firebaseapp.com"
    ],
    "method": ["GET", "POST", "PUT"],
    "responseHeader": [
      "Content-Type",
      "Authorization",
      "x-goog-meta-*",
      "x-goog-upload-*",
      "x-goog-resumable"
    ],
    "maxAgeSeconds": 3600
  }
]
```

Observações:
- O `origin` não suporta wildcard por porta (`http://localhost:*`), use `"*"` em dev ou a porta fixa do seu servidor.
- `OPTIONS` é tratado automaticamente no preflight; você precisa listar apenas os métodos que serão usados (`GET`, `POST`, `PUT`).

## Passo 2 — Aplicar CORS ao bucket

Observação sobre nomes de bucket:
- Buckets criados antes de 30/10/2024 usam o formato `PROJECT_ID.appspot.com`.
- Buckets criados a partir de 30/10/2024 usam o formato `PROJECT_ID.firebasestorage.app`.
- Verifique o nome do seu bucket na aba "Storage" do Firebase Console e use esse nome nos comandos abaixo.

1) Via `gsutil` (Windows/PowerShell):

```powershell
# Substitua pelo nome do seu bucket. Exemplo (novo formato):
gsutil cors set cors.json gs://financeiro-9cb44.firebasestorage.app
gsutil cors get gs://financeiro-9cb44.firebasestorage.app

# Se o seu bucket for do formato antigo:
# gsutil cors set cors.json gs://financeiro-9cb44.appspot.com
# gsutil cors get gs://financeiro-9cb44.appspot.com
```

2) Via Console do Google Cloud:
- Acesse `Storage` → `Buckets` → selecione seu bucket (ex.: `financeiro-9cb44.firebasestorage.app` ou `financeiro-9cb44.appspot.com`).
- Aba `Configuration` → seção `CORS` → `Edit` → cole o JSON → `Save`.

Propagação: pode levar alguns minutos. Atualize a página e tente novamente (teste em aba anônima para evitar cache).

## Passo 3 — Verificar
- Tente o upload novamente pelo app web.
- Se quiser testar o preflight manualmente, use um cliente HTTP (ex.: `curl` ou Postman) para enviar uma requisição `OPTIONS` com os headers de origem e método. Em geral, basta validar no navegador que o erro de CORS desapareceu.

## Dicas
- Mantenha regras do Firebase Storage alinhadas (limite de 20MB e content-type `application/pdf` para PDFs).
- Se o erro persistir, verifique se está usando o bucket correto (ex.: `financeiro-9cb44.firebasestorage.app`) e se está autenticado.