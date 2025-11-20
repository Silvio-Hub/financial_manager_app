import 'dart:typed_data';

/// Receipt storage operations contract for the domain layer.
abstract class ReceiptRepository {
  /// Uploads a receipt and returns its public URL (or path) when applicable.
  Future<String> upload(
    String uid,
    String transactionId,
    Uint8List bytes, {
    String? contentType,
  });

  /// Deletes a stored receipt.
  Future<void> delete(String uid, String transactionId);
}