import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'logger_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifica se o usuário está autenticado
  static bool get isUserAuthenticated => _auth.currentUser != null;

  /// Obtém o ID do usuário atual
  static String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user.uid;
  }

  /// Verifica se o Firebase Storage está configurado e acessível
  static Future<bool> checkStorageConnection() async {
    try {
      if (!isUserAuthenticated) {
        return false;
      }

      // Tenta acessar uma referência simples para verificar conectividade
      final testRef = _storage.ref().child('test_connection');
      
      // Tenta obter metadados (operação leve que verifica conectividade)
      await testRef.getMetadata().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout na verificação'),
      );
      
      return true;
    } catch (e) {
      LoggerService.error('Erro na verificação do Storage: $e', e);
      return false;
    }
  }

  /// Faz upload de um arquivo para o Firebase Storage
  /// 
  /// [file] - Arquivo a ser enviado (File para mobile/desktop, Uint8List para web)
  /// [fileName] - Nome do arquivo
  /// [transactionId] - ID da transação associada
  /// [fileExtension] - Extensão do arquivo
  /// 
  /// Retorna a URL de download do arquivo
  static Future<String> uploadReceipt({
    required dynamic file, // File ou Uint8List
    required String fileName,
    required String transactionId,
    required String fileExtension,
  }) async {
    if (!isUserAuthenticated) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    // Verificar conectividade antes do upload
    LoggerService.info('Verificando conectividade com Firebase Storage...');
    final isConnected = await checkStorageConnection();
    if (!isConnected) {
      throw Exception(
        'Firebase Storage não está configurado ou acessível.\n'
        'Verifique se:\n'
        '1. O Firebase Storage está habilitado no console\n'
        '2. As regras de segurança estão configuradas\n'
        '3. Você tem conexão com a internet'
      );
    }

    try {
      LoggerService.info('Iniciando upload do recibo...');
      
      // Criar caminho único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = _sanitizeFileName(fileName);
      final fullFileName = '${timestamp}_$sanitizedFileName.$fileExtension';
      
      // Caminho: receipts/userId/transactionId/arquivo
      final filePath = 'receipts/$currentUserId/$transactionId/$fullFileName';
      LoggerService.info('Caminho do arquivo: $filePath');
      
      // Referência do arquivo no Storage
      final ref = _storage.ref().child(filePath);
      
      // Fazer upload baseado no tipo de arquivo
      UploadTask uploadTask;
      if (file is File) {
        // Para mobile/desktop
        LoggerService.info('Upload de arquivo File (${file.lengthSync()} bytes)');
        uploadTask = ref.putFile(file);
      } else if (file is Uint8List) {
        // Para web
        LoggerService.info('Upload de arquivo Uint8List (${file.length} bytes)');
        uploadTask = ref.putData(file);
      } else {
        throw Exception('Tipo de arquivo não suportado');
      }

      // Aguardar conclusão do upload com timeout
      LoggerService.info('Aguardando conclusão do upload...');
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload cancelado por timeout (5 minutos)');
        },
      );
      
      // Obter URL de download
      LoggerService.info('Upload concluído, obtendo URL de download...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      LoggerService.info('URL de download obtida: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      LoggerService.error('FirebaseException: ${e.code} - ${e.message}', e);
      
      // Tratar erros específicos do Firebase
      String errorMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage = 'Sem permissão para fazer upload. Verifique se está logado e se as regras do Storage estão configuradas.';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload cancelado pelo usuário.';
          break;
        case 'storage/unknown':
          errorMessage = 'Erro desconhecido no servidor. Tente novamente.\nDetalhes: ${e.message}';
          break;
        case 'storage/object-not-found':
          errorMessage = 'Arquivo não encontrado.';
          break;
        case 'storage/bucket-not-found':
          errorMessage = 'Firebase Storage não está configurado corretamente.\nVerifique se o Storage está habilitado no console do Firebase.';
          break;
        case 'storage/project-not-found':
          errorMessage = 'Projeto Firebase não encontrado.\nVerifique a configuração do projeto.';
          break;
        case 'storage/quota-exceeded':
          errorMessage = 'Cota de armazenamento excedida. Contate o administrador.';
          break;
        case 'storage/unauthenticated':
          errorMessage = 'Usuário não autenticado. Faça login novamente.';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage = 'Muitas tentativas de upload. Tente novamente mais tarde.';
          break;
        case 'storage/invalid-format':
          errorMessage = 'Formato de arquivo inválido.';
          break;
        case 'storage/invalid-argument':
          errorMessage = 'Argumentos inválidos para o upload.';
          break;
        default:
          errorMessage = 'Erro no upload: ${e.code}\nDetalhes: ${e.message}';
      }
      
      LoggerService.error('Erro detalhado: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      LoggerService.error('Erro geral no upload: $e', e);
      throw Exception('Erro inesperado no upload: $e');
    }
  }

  /// Lista todos os recibos de uma transação
  static Future<List<ReceiptInfo>> getTransactionReceipts(String transactionId) async {
    if (!isUserAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final folderPath = 'receipts/$currentUserId/$transactionId/';
      final ref = _storage.ref().child(folderPath);
      
      final result = await ref.listAll();
      
      List<ReceiptInfo> receipts = [];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        final metadata = await item.getMetadata();
        
        receipts.add(ReceiptInfo(
          name: item.name,
          url: url,
          size: metadata.size ?? 0,
          uploadDate: metadata.timeCreated ?? DateTime.now(),
          contentType: metadata.contentType ?? 'application/octet-stream',
        ));
      }
      
      // Ordenar por data de upload (mais recente primeiro)
      receipts.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      
      return receipts;
    } catch (e) {
      throw Exception('Erro ao listar recibos: $e');
    }
  }

  /// Deleta um recibo específico
  static Future<void> deleteReceipt({
    required String transactionId,
    required String fileName,
  }) async {
    if (!isUserAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final filePath = 'receipts/$currentUserId/$transactionId/$fileName';
      final ref = _storage.ref().child(filePath);
      
      await ref.delete();
    } catch (e) {
      throw Exception('Erro ao deletar recibo: $e');
    }
  }

  /// Deleta todos os recibos de uma transação
  static Future<void> deleteAllTransactionReceipts(String transactionId) async {
    if (!isUserAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final folderPath = 'receipts/$currentUserId/$transactionId/';
      final ref = _storage.ref().child(folderPath);
      
      final result = await ref.listAll();
      
      // Deletar todos os arquivos
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Erro ao deletar recibos da transação: $e');
    }
  }

  /// Verifica se um arquivo é uma imagem válida
  static bool isValidImageFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  /// Verifica se um arquivo é um PDF
  static bool isPdfFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return extension == '.pdf';
  }

  /// Verifica se o arquivo é suportado
  static bool isSupportedFile(String fileName) {
    return isValidImageFile(fileName) || isPdfFile(fileName);
  }

  /// Obtém o tipo de arquivo baseado na extensão
  static String getFileType(String fileName) {
    if (isValidImageFile(fileName)) {
      return 'image';
    } else if (isPdfFile(fileName)) {
      return 'pdf';
    } else {
      return 'unknown';
    }
  }

  /// Sanitiza o nome do arquivo removendo caracteres especiais
  static String _sanitizeFileName(String fileName) {
    // Remove caracteres especiais e espaços
    return fileName
        .replaceAll(RegExp(r'[^\w\s-.]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Formata o tamanho do arquivo em formato legível
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// Classe para informações do recibo
class ReceiptInfo {
  final String name;
  final String url;
  final int size;
  final DateTime uploadDate;
  final String contentType;

  ReceiptInfo({
    required this.name,
    required this.url,
    required this.size,
    required this.uploadDate,
    required this.contentType,
  });

  /// Obtém o tipo do arquivo
  String get fileType => StorageService.getFileType(name);

  /// Obtém o tamanho formatado
  String get formattedSize => StorageService.formatFileSize(size);

  /// Verifica se é uma imagem
  bool get isImage => StorageService.isValidImageFile(name);

  /// Verifica se é um PDF
  bool get isPdf => StorageService.isPdfFile(name);
}