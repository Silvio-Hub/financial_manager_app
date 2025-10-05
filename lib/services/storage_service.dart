import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'logger_service.dart';
import 'firestore_service.dart';
import '../firebase_options.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
  );
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int maxUploadSizeBytes = 20 * 1024 * 1024;

  static bool get isUserAuthenticated => _auth.currentUser != null;

  static String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user.uid;
  }

  static Future<bool> checkStorageConnection({String? transactionId}) async {
    try {
      LoggerService.info('Verificando conectividade do Storage...');

      if (!isUserAuthenticated) {
        LoggerService.warning(
          'Usuário não autenticado para verificação do Storage',
        );
        return false;
      }

      if (transactionId == null || transactionId.isEmpty) {
        LoggerService.info(
          'Sem transactionId; usuário autenticado. Pulando verificação de list e seguindo.',
        );
        return true;
      }

      LoggerService.info(
        'Usuário autenticado, testando acesso ao Storage (list) em receipts/$currentUserId/$transactionId ...',
      );

      final String testPath = 'receipts/$currentUserId/$transactionId';
      final Reference testRef = _storage.ref().child(testPath);
      LoggerService.info('Referência para verificação: ${testRef.fullPath}');

      final ListResult result = await testRef.list(
        const ListOptions(maxResults: 1),
      );
      LoggerService.info(
        'Verificação concluída. Itens encontrados: ${result.items.length}, pastas: ${result.prefixes.length}',
      );
      return true;
    } on FirebaseException catch (e) {
      LoggerService.error(
        'Falha na verificação do Storage: ${e.code} - ${e.message}',
        e,
      );
      if (e.code == 'storage/bucket-not-found' ||
          e.code == 'storage/project-not-found' ||
          (e.message?.contains('404') ?? false)) {
        LoggerService.error(
          'Possível Storage desabilitado ou bucket incorreto. Verifique console do Firebase.',
        );
      } else if (e.code == 'storage/unauthorized' ||
          e.code == 'storage/unauthenticated') {
        LoggerService.warning(
          'Sem permissão para acessar o Storage. Verifique regras e login.',
        );
      }
      return false;
    } catch (e) {
      LoggerService.error('Erro inesperado na verificação do Storage: $e', e);
      return false;
    }
  }

  static Future<String> uploadReceipt({
    required dynamic file,
    required String fileName,
    required String transactionId,
    required String fileExtension,
  }) async {
    try {
      LoggerService.info('=== INICIANDO UPLOAD DE RECIBO (STORAGE) ===');
      LoggerService.info('Arquivo: $fileName');
      LoggerService.info('Transação: $transactionId');
      LoggerService.info('Extensão: $fileExtension');

      final receiptId = await uploadReceiptLocal(
        file: file,
        fileName: fileName,
        transactionId: transactionId,
        fileExtension: fileExtension,
      );

      LoggerService.info('Upload concluído com sucesso! ID: $receiptId');

      return receiptId;
    } on FirebaseException catch (e) {
      LoggerService.error('FirebaseException: ${e.code} - ${e.message}', e);

      String errorMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage =
              'Sem permissão para fazer upload. Verifique se está logado e se as regras do Storage estão configuradas.';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload cancelado pelo usuário.';
          break;
        case 'storage/unknown':
          errorMessage =
              'Erro desconhecido no servidor. Tente novamente.\nDetalhes: ${e.message}';
          break;
        case 'storage/object-not-found':
          errorMessage = 'Arquivo não encontrado.';
          break;
        case 'storage/bucket-not-found':
          errorMessage =
              'Firebase Storage não está configurado corretamente.\nVerifique se o Storage está habilitado no console do Firebase.';
          break;
        case 'storage/project-not-found':
          errorMessage =
              'Projeto Firebase não encontrado.\nVerifique a configuração do projeto.';
          break;
        case 'storage/quota-exceeded':
          errorMessage =
              'Cota de armazenamento excedida. Contate o administrador.';
          break;
        case 'storage/unauthenticated':
          errorMessage = 'Usuário não autenticado. Faça login novamente.';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage =
              'Muitas tentativas de upload. Tente novamente mais tarde.';
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

  static Future<List<ReceiptInfo>> getTransactionReceipts(
    String transactionId,
  ) async {
    if (!isUserAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    try {
      LoggerService.info(
        'Buscando recibos locais para transação: $transactionId',
      );

      final receiptsQuery = await FirebaseFirestore.instance
          .collection('receipts')
          .where('userId', isEqualTo: currentUserId)
          .where('transactionId', isEqualTo: transactionId)
          .orderBy('uploadDate', descending: true)
          .get();

      List<ReceiptInfo> receipts = [];
      for (final doc in receiptsQuery.docs) {
        final data = doc.data();

        receipts.add(
          ReceiptInfo(
            name: data['fileName'] ?? 'Arquivo sem nome',
            url: doc.id,
            size: data['fileSize'] ?? 0,
            uploadDate:
                (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            contentType: data['contentType'] ?? 'application/octet-stream',
          ),
        );
      }

      LoggerService.info(
        'Encontrados ${receipts.length} recibos para a transação',
      );
      return receipts;
    } catch (e) {
      LoggerService.error('Erro ao listar recibos: $e');
      throw Exception('Erro ao listar recibos: $e');
    }
  }

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

      String? downloadUrl;
      try {
        downloadUrl = await ref.getDownloadURL();
      } catch (e) {
        LoggerService.warning(
          'Não foi possível obter URL do arquivo antes de deletar: $e',
        );
      }

      await ref.delete();

      if (downloadUrl != null) {
        try {
          LoggerService.info(
            'Removendo URL do recibo da transação no Firestore...',
          );
          await FirestoreService.removeReceiptFromTransaction(
            transactionId,
            downloadUrl,
          );
          LoggerService.info('URL do recibo removida da transação com sucesso');
        } catch (e) {
          LoggerService.warning(
            'Erro ao remover URL do recibo da transação: $e',
          );
        }
      }
    } catch (e) {
      throw Exception('Erro ao deletar recibo: $e');
    }
  }

  static Future<String?> getStorageDownloadUrl({
    required String transactionId,
    required String fileName,
  }) async {
    if (!isUserAuthenticated) {
      LoggerService.error('Tentativa de obter URL de Storage sem autenticação');
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }
    try {
      final filePath = 'receipts/$currentUserId/$transactionId/$fileName';
      LoggerService.info('Obtendo URL de download do Storage: $filePath');
      final ref = _storage.ref().child(filePath);
      final url = await ref.getDownloadURL();
      LoggerService.info('URL do Storage obtida com sucesso');
      return url;
    } on FirebaseException catch (e) {
      LoggerService.warning(
        'Falha ao obter URL do Storage: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      LoggerService.warning('Erro ao obter URL do Storage: $e');
      return null;
    }
  }

  static Future<void> deleteAllTransactionReceipts(String transactionId) async {
    if (!isUserAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final folderPath = 'receipts/$currentUserId/$transactionId/';
      final ref = _storage.ref().child(folderPath);

      final result = await ref.listAll();

      for (final item in result.items) {
        await item.delete();
      }

      try {
        LoggerService.info(
          'Limpando URLs de recibos da transação no Firestore...',
        );
        await FirestoreService.updateTransactionReceipts(transactionId, []);
        LoggerService.info('URLs de recibos limpas da transação com sucesso');
      } catch (e) {
        LoggerService.warning(
          'Erro ao limpar URLs de recibos da transação: $e',
        );
      }
    } catch (e) {
      throw Exception('Erro ao deletar recibos da transação: $e');
    }
  }

  static bool isValidImageFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.heic',
      '.heif',
    ].contains(extension);
  }

  static bool isPdfFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return extension == '.pdf';
  }

  static bool isSupportedFile(String fileName) {
    return isValidImageFile(fileName) || isPdfFile(fileName);
  }

  static String getFileType(String fileName) {
    if (isValidImageFile(fileName)) {
      return 'image';
    } else if (isPdfFile(fileName)) {
      return 'pdf';
    } else {
      return 'unknown';
    }
  }

  static String _sanitizeFileName(String fileName) {
    final justName = path.basename(fileName);
    final lastDot = justName.lastIndexOf('.');
    final baseName = lastDot >= 0 ? justName.substring(0, lastDot) : justName;

    final sanitized = baseName
        .replaceAll(RegExp(r'[^\w\s-.]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'\.+'), '.')
        .toLowerCase()
        .trim();

    return sanitized.replaceAll(RegExp(r'^[_.]+|[_.]+$'), '');
  }

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

  static Future<String> uploadReceiptLocal({
    required dynamic file,
    required String fileName,
    required String transactionId,
    required String fileExtension,
  }) async {
    LoggerService.info('=== INICIANDO UPLOAD PARA STORAGE ===');
    LoggerService.info('fileName: $fileName');
    LoggerService.info('transactionId: $transactionId');
    LoggerService.info('fileExtension: $fileExtension');
    LoggerService.info('file type: ${file.runtimeType}');
    LoggerService.info(
      'Bucket configurado: ${DefaultFirebaseOptions.currentPlatform.storageBucket}',
    );

    if (!isUserAuthenticated) {
      LoggerService.error('Usuário não autenticado');
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }

    LoggerService.info('Usuário autenticado: $currentUserId');

    try {
      Uint8List bytes;
      if (file is File) {
        bytes = await file.readAsBytes();
      } else if (file is Uint8List) {
        bytes = file;
      } else {
        throw Exception('Tipo de arquivo não suportado');
      }

      LoggerService.info('Lendo bytes do arquivo (${bytes.length} bytes)');
      if (bytes.length > maxUploadSizeBytes) {
        LoggerService.error(
          'Arquivo excede limite de 20MB (${bytes.length} bytes)',
        );
        throw Exception('Arquivo muito grande. Limite: 20MB.');
      }

      final derivedExt = path
          .extension(fileName)
          .replaceFirst('.', '')
          .toLowerCase();
      String effectiveExtension;
      if (derivedExt.isEmpty) {
        effectiveExtension = fileExtension.toLowerCase();
      } else {
        effectiveExtension = derivedExt;
        if (fileExtension.toLowerCase() != derivedExt) {
          LoggerService.warning(
            'Extensão passada ("$fileExtension") difere da derivada ("$derivedExt"). Usando a derivada.',
          );
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = _sanitizeFileName(fileName);
      LoggerService.info('sanitizedFileName: $sanitizedFileName');
      final fullFileName =
          '${timestamp}_$sanitizedFileName.$effectiveExtension';
      LoggerService.info('fullFileName: $fullFileName');
      final storagePath =
          'receipts/$currentUserId/$transactionId/$fullFileName';
      final contentType = _getContentType(effectiveExtension);
      LoggerService.info('contentType: $contentType');

      LoggerService.info('Subindo para Storage em: $storagePath');
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(contentType: contentType);
      if (file is File) {
        await ref.putFile(file, metadata);
      } else {
        await ref.putData(bytes, metadata);
      }
      final downloadUrl = await ref.getDownloadURL();
      LoggerService.info('Upload no Storage concluído. URL obtida.');

      final receiptData = {
        'fileName': fullFileName,
        'originalFileName': fileName,
        'fileExtension': fileExtension,
        'fileSize': bytes.length,
        'transactionId': transactionId,
        'userId': currentUserId,
        'uploadDate': FieldValue.serverTimestamp(),
        'contentType': contentType,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
      };

      LoggerService.info('Salvando recibo no Firestore...');

      final docRef = await FirebaseFirestore.instance
          .collection('receipts')
          .add(receiptData);

      LoggerService.info('Recibo salvo com ID: ${docRef.id}');

      try {
        LoggerService.info('Adicionando URL do recibo à transação...');
        await FirestoreService.addReceiptToTransaction(
          transactionId,
          downloadUrl,
        );
        LoggerService.info('URL do recibo adicionada à transação com sucesso');
      } catch (e) {
        LoggerService.warning(
          'Erro ao adicionar URL do recibo à transação: $e',
        );
      }

      return docRef.id;
    } on FirebaseException catch (e) {
      LoggerService.error(
        'FirebaseException no upload: ${e.code} - ${e.message}',
        e,
      );
      rethrow;
    } catch (e) {
      LoggerService.error('Erro no upload para Storage: $e', e);
      throw Exception('Erro no upload: $e');
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<Map<String, dynamic>?> getLocalReceipt(
    String receiptId, {
    String? fileName,
  }) async {
    try {
      if (!isUserAuthenticated) {
        LoggerService.error('Tentativa de recuperar recibo sem autenticação');
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      LoggerService.info('Recuperando recibo local: $receiptId');

      final doc = await FirebaseFirestore.instance
          .collection('receipts')
          .doc(receiptId)
          .get();

      if (!doc.exists) {
        LoggerService.warning('Recibo não encontrado por ID: $receiptId');
        if (fileName != null && fileName.isNotEmpty) {
          LoggerService.info('Tentando fallback por fileName: $fileName');
          final altQuery = await FirebaseFirestore.instance
              .collection('receipts')
              .where('userId', isEqualTo: currentUserId)
              .where('fileName', isEqualTo: fileName)
              .orderBy('uploadDate', descending: true)
              .limit(1)
              .get();
          if (altQuery.docs.isNotEmpty) {
            final altDoc = altQuery.docs.first;
            final altData = altDoc.data();
            altData['id'] = altDoc.id;
            LoggerService.info('Recibo encontrado via fallback por fileName');

            try {
              final String? txnId = (altData['transactionId'] is String)
                  ? altData['transactionId'] as String
                  : null;
              final String? fname = (altData['fileName'] is String)
                  ? altData['fileName'] as String
                  : null;
              final String? base64Data = (altData['base64Data'] is String)
                  ? altData['base64Data'] as String
                  : null;
              if ((base64Data == null || base64Data.isEmpty) &&
                  txnId != null &&
                  fname != null) {
                final filePath = 'receipts/$currentUserId/$txnId/$fname';
                LoggerService.info(
                  'Fallback Storage (via fileName): baixando bytes de $filePath',
                );
                final ref = _storage.ref().child(filePath);
                final Uint8List? bytes = await ref.getData(20 * 1024 * 1024);
                if (bytes != null) {
                  altData['base64Data'] = base64Encode(bytes);
                  altData['fileSize'] = bytes.length;
                  LoggerService.info(
                    'Fallback Storage concluído (via fileName): ${bytes.length} bytes',
                  );
                } else {
                  LoggerService.warning(
                    'Fallback Storage (via fileName): bytes retornaram null',
                  );
                }
                try {
                  final url = await ref.getDownloadURL();
                  altData['downloadUrl'] = url;
                } catch (e) {
                  LoggerService.warning(
                    'Falha ao obter URL de download (via fileName): $e',
                  );
                }
              }
            } catch (e) {
              LoggerService.warning(
                'Falha no fallback de Storage (via fileName): $e',
              );
            }
            return altData;
          }
        }
        return null;
      }

      final data = doc.data()!;
      final userId = data['userId'];
      if (userId != currentUserId) {
        LoggerService.error(
          'Recibo pertence a outro usuário. userId=$userId, currentUserId=$currentUserId',
        );
        throw Exception('Sem permissão para acessar este recibo.');
      }
      final String? base64Data = (data['base64Data'] is String)
          ? data['base64Data'] as String
          : null;
      final hasDataUri = base64Data?.startsWith('data:') == true;
      LoggerService.info(
        'Recibo meta: ext=${data['fileExtension']}, contentType=${data['contentType']}, size=${data['fileSize']}, base64Length=${base64Data?.length ?? 0}, hasDataUri=$hasDataUri',
      );

      if (base64Data == null || base64Data.isEmpty) {
        try {
          final String? txnId = (data['transactionId'] is String)
              ? data['transactionId'] as String
              : null;
          final String? fname = (data['fileName'] is String)
              ? data['fileName'] as String
              : null;
          if (txnId != null && fname != null) {
            final filePath = 'receipts/$currentUserId/$txnId/$fname';
            LoggerService.info('Fallback Storage: baixando bytes de $filePath');
            final ref = _storage.ref().child(filePath);
            final Uint8List? bytes = await ref.getData(20 * 1024 * 1024);
            if (bytes != null) {
              data['base64Data'] = base64Encode(bytes);
              data['fileSize'] = bytes.length;
              LoggerService.info(
                'Fallback Storage concluído: ${bytes.length} bytes',
              );
            } else {
              LoggerService.warning('Fallback Storage: bytes retornaram null');
            }
            try {
              final url = await ref.getDownloadURL();
              data['downloadUrl'] = url;
            } catch (e) {
              LoggerService.warning('Falha ao obter URL de download: $e');
            }
          } else {
            LoggerService.warning(
              'Fallback Storage: transactionId ou fileName ausente no documento',
            );
          }
        } catch (e) {
          LoggerService.warning('Falha no fallback de Storage: $e');
        }
      }
      data['id'] = doc.id;

      LoggerService.info('Recibo recuperado com sucesso');
      return data;
    } on FirebaseException catch (e) {
      LoggerService.error(
        'FirebaseException ao recuperar recibo: ${e.code} - ${e.message}',
        e,
      );
      throw Exception('Erro Firebase ao recuperar recibo: ${e.code}');
    } catch (e) {
      LoggerService.error('Erro ao recuperar recibo local: $e', e);
      throw Exception('Erro ao recuperar recibo: $e');
    }
  }

  static Future<String> uploadReceiptAndGetDownloadUrl({
    required dynamic file,
    required String fileName,
    required String transactionId,
    String? fileExtension,
  }) async {
    LoggerService.info('=== UPLOAD SEGURO: iniciar ===');

    if (!isUserAuthenticated) {
      LoggerService.error('Upload bloqueado: usuário não autenticado');
      throw Exception(
        'Usuário não autenticado. Faça login para enviar recibos.',
      );
    }
    final uid = currentUserId;
    if (uid.isEmpty) {
      LoggerService.error('Upload bloqueado: UID inválido');
      throw Exception('Falha ao obter UID do usuário autenticado.');
    }

    if (transactionId.isEmpty) {
      throw Exception(
        'TransactionId inválido. Salve a transação antes de enviar recibos.',
      );
    }

    LoggerService.info(
      'Bucket: ${DefaultFirebaseOptions.currentPlatform.storageBucket}',
    );
    LoggerService.info(
      'UID: $uid | transactionId: $transactionId | fileName: $fileName',
    );

    try {
      Uint8List bytes;
      if (file is File) {
        bytes = await file.readAsBytes();
      } else if (file is Uint8List) {
        bytes = file;
      } else {
        throw Exception('Tipo de arquivo não suportado. Use imagem ou PDF.');
      }

      final size = bytes.length;
      LoggerService.info(
        'Tamanho do arquivo: ${formatFileSize(size)} ($size bytes)',
      );
      if (size > maxUploadSizeBytes) {
        throw Exception('Arquivo muito grande. Limite: 20MB.');
      }

      if (!isSupportedFile(fileName)) {
        throw Exception(
          'Tipo de arquivo não suportado. Use apenas imagens ou PDF.',
        );
      }

      final derivedExt = path
          .extension(fileName)
          .replaceFirst('.', '')
          .toLowerCase();
      final effectiveExtension = (derivedExt.isNotEmpty
          ? derivedExt
          : (fileExtension ?? '').toLowerCase());
      if (effectiveExtension.isEmpty) {
        throw Exception('Não foi possível determinar a extensão do arquivo.');
      }
      final contentType = _getContentType(effectiveExtension);
      LoggerService.info(
        'contentType: $contentType | ext: $effectiveExtension',
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = _sanitizeFileName(fileName);
      final fullFileName =
          '${timestamp}_$sanitizedFileName.$effectiveExtension';
      final storagePath = 'receipts/$uid/$transactionId/$fullFileName';
      LoggerService.info('storagePath: $storagePath');

      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(contentType: contentType);
      if (file is File) {
        await ref.putFile(file, metadata);
      } else {
        await ref.putData(bytes, metadata);
      }

      final downloadUrl = await ref.getDownloadURL();
      LoggerService.info('Upload seguro concluído. URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      LoggerService.error(
        'Falha Firebase no upload seguro: ${e.code} - ${e.message}',
        e,
      );
      rethrow;
    } catch (e) {
      LoggerService.error('Falha no upload seguro: $e', e);
      throw Exception('Erro ao enviar recibo: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLocalTransactionReceipts(
    String transactionId,
  ) async {
    try {
      LoggerService.info(
        'Listando recibos locais da transação: $transactionId',
      );

      final query = await FirebaseFirestore.instance
          .collection('receipts')
          .where('transactionId', isEqualTo: transactionId)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('uploadDate', descending: true)
          .get();

      final receipts = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      LoggerService.info('${receipts.length} recibos encontrados');
      return receipts;
    } catch (e) {
      LoggerService.error('Erro ao listar recibos locais: $e', e);
      throw Exception('Erro ao listar recibos: $e');
    }
  }

  static Future<void> deleteLocalReceipt(String receiptId) async {
    try {
      LoggerService.info('Deletando recibo local: $receiptId');

      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(receiptId)
          .delete();

      LoggerService.info('Recibo deletado com sucesso');
    } catch (e) {
      LoggerService.error('Erro ao deletar recibo local: $e', e);
      throw Exception('Erro ao deletar recibo: $e');
    }
  }
}

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

  String get fileType => StorageService.getFileType(name);

  String get formattedSize => StorageService.formatFileSize(size);

  bool get isImage {
    final ct = contentType.toLowerCase();
    if (ct.isNotEmpty) {
      return ct.startsWith('image/');
    }
    return StorageService.isValidImageFile(name);
  }

  bool get isPdf {
    final ct = contentType.toLowerCase();
    if (ct.isNotEmpty) {
      return ct == 'application/pdf';
    }
    return StorageService.isPdfFile(name);
  }
}
