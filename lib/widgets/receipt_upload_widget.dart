import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class ReceiptUploadWidget extends StatefulWidget {
  final String? transactionId;
  final Function(List<ReceiptInfo>)? onReceiptsChanged;
  final bool readOnly;

  const ReceiptUploadWidget({
    super.key,
    this.transactionId,
    this.onReceiptsChanged,
    this.readOnly = false,
  });

  @override
  State<ReceiptUploadWidget> createState() => _ReceiptUploadWidgetState();
}

class _ReceiptUploadWidgetState extends State<ReceiptUploadWidget> {
  List<ReceiptInfo> _receipts = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadReceipts();
    }
  }

  @override
  void didUpdateWidget(ReceiptUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactionId != oldWidget.transactionId) {
      if (widget.transactionId != null) {
        _loadReceipts();
      } else {
        setState(() {
          _receipts.clear();
        });
      }
    }
  }

  Future<void> _loadReceipts() async {
    if (widget.transactionId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final receipts = await StorageService.getTransactionReceipts(widget.transactionId!);
      setState(() {
        _receipts = receipts;
      });
      widget.onReceiptsChanged?.call(_receipts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar recibos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (widget.transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a transação primeiro para adicionar recibos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar opções de seleção
      final source = await _showSourceSelection();
      if (source == null) return;

      setState(() {
        _isUploading = true;
      });

      dynamic file;
      String fileName;
      String fileExtension;

      if (source == 'camera' || source == 'gallery') {
        // Usar ImagePicker para câmera ou galeria
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (pickedFile == null) return;

        fileName = pickedFile.name;
        fileExtension = fileName.split('.').last.toLowerCase();

        if (kIsWeb) {
          file = await pickedFile.readAsBytes();
        } else {
          file = File(pickedFile.path);
        }
      } else {
        // Usar FilePicker para documentos
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) return;

        final pickedFile = result.files.first;
        fileName = pickedFile.name;
        fileExtension = fileName.split('.').last.toLowerCase();

        if (kIsWeb) {
          file = pickedFile.bytes;
        } else {
          file = File(pickedFile.path!);
        }
      }

      // Verificar se o arquivo é suportado
      if (!StorageService.isSupportedFile(fileName)) {
        throw Exception('Tipo de arquivo não suportado. Use apenas imagens (JPG, PNG, etc.) ou PDF.');
      }

      // Fazer upload
      await StorageService.uploadReceipt(
        file: file,
        fileName: fileName,
        transactionId: widget.transactionId!,
        fileExtension: fileExtension,
      );

      // Recarregar lista de recibos
      await _loadReceipts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _showSourceSelection() async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Documentos'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReceipt(ReceiptInfo receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir o recibo "${receipt.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await StorageService.deleteReceipt(
        transactionId: widget.transactionId!,
        fileName: receipt.name,
      );

      await _loadReceipts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewReceipt(ReceiptInfo receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptViewerScreen(receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recibos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isUploading ? 'Enviando...' : 'Adicionar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_receipts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum recibo adicionado',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _receipts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final receipt = _receipts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: receipt.isImage ? Colors.blue : Colors.red,
                    child: Icon(
                      receipt.isImage ? Icons.image : Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    receipt.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${receipt.formattedSize} • ${_formatDate(receipt.uploadDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _viewReceipt(receipt),
                        tooltip: 'Visualizar',
                      ),
                      if (!widget.readOnly)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteReceipt(receipt),
                          tooltip: 'Excluir',
                          color: Colors.red,
                        ),
                    ],
                  ),
                  onTap: () => _viewReceipt(receipt),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class ReceiptViewerScreen extends StatelessWidget {
  final ReceiptInfo receipt;

  const ReceiptViewerScreen({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              // Abrir URL em navegador externo
              // Implementar conforme necessário
            },
            tooltip: 'Abrir em nova aba',
          ),
        ],
      ),
      body: Center(
        child: receipt.isImage
            ? InteractiveViewer(
                child: Image.network(
                  receipt.url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Erro ao carregar imagem'),
                      ],
                    );
                  },
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    receipt.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(receipt.formattedSize),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Abrir PDF em navegador
                      // Implementar conforme necessário
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir PDF'),
                  ),
                ],
              ),
      ),
    );
  }
}