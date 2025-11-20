import 'dart:typed_data';
import '../../domain/repositories/receipt_repository.dart' as domain;
import '../../services/storage_service.dart';

class ReceiptRepositoryImpl implements domain.ReceiptRepository {
  String _extFromContentType(String? contentType) {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.startsWith('image/jpeg') || ct == 'jpeg' || ct == 'jpg') return 'jpg';
    if (ct.startsWith('image/png') || ct == 'png') return 'png';
    if (ct == 'application/pdf' || ct == 'pdf') return 'pdf';
    return 'bin';
  }

  @override
  Future<String> upload(
    String uid,
    String transactionId,
    Uint8List bytes, {
    String? contentType,
  }) async {
    final ext = _extFromContentType(contentType);
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final url = await StorageService.uploadReceiptAndGetDownloadUrl(
      file: bytes,
      fileName: fileName,
      transactionId: transactionId,
      fileExtension: ext,
    );
    return url;
  }

  @override
  Future<void> delete(String uid, String transactionId) async {
    // Remove todos os recibos associados à transação do usuário
    final receipts = await StorageService.getTransactionReceipts(transactionId);
    for (final r in receipts) {
      await StorageService.deleteReceipt(
        transactionId: transactionId,
        fileName: r.name,
      );
    }
  }
}