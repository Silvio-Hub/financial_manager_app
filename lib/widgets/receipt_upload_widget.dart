import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/storage_service.dart';
import '../services/logger_service.dart';

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

  Future<bool> _ensureAuthenticated() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) {
        try {
          LoggerService.warning(
            'Upload bloqueado: usuário não autenticado. Redirecionando para login.',
          );
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faça login para enviar recibos.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
        return false;
      }
      return true;
    } catch (e) {
      final signedIn = StorageService.isUserAuthenticated;
      if (!signedIn && mounted) {
        try {
          LoggerService.warning(
            'Provider indisponível para auth; fallback indica não autenticado.',
          );
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faça login para enviar recibos.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return signedIn;
    }
  }

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
      final receipts = await StorageService.getTransactionReceipts(
        widget.transactionId!,
      );
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
    LoggerService.info('=== INICIANDO SELEÇÃO DE ARQUIVO ===');

    if (widget.transactionId == null) {
      LoggerService.warning('TransactionId é null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a transação primeiro para adicionar recibos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isAuth = await _ensureAuthenticated();
    if (!isAuth) {
      return;
    }

    LoggerService.info('TransactionId: ${widget.transactionId}');

    try {
      LoggerService.info('Mostrando opções de seleção...');
      final source = await _showSourceSelection();
      LoggerService.info('Fonte selecionada: $source');
      if (source == null) return;

      setState(() {
        _isUploading = true;
      });

      dynamic file;
      String fileName;
      String fileExtension;

      if (source == 'camera' || source == 'gallery') {
        LoggerService.info('Usando ImagePicker para $source');
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (pickedFile == null) {
          LoggerService.info('Nenhum arquivo selecionado');
          return;
        }

        fileName = pickedFile.name;
        fileExtension = fileName.split('.').last.toLowerCase();
        LoggerService.info('Arquivo selecionado: $fileName (.$fileExtension)');

        if (kIsWeb) {
          LoggerService.info('Lendo arquivo como bytes (Web)');
          file = await pickedFile.readAsBytes();
        } else {
          LoggerService.info(
            'Criando File object (Mobile): ${pickedFile.path}',
          );
          file = File(pickedFile.path);
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'jpg',
            'jpeg',
            'png',
            'gif',
            'bmp',
            'webp',
            'heic',
            'heif',
          ],
          allowMultiple: false,
          withData: true,
        );

        if (result == null || result.files.isEmpty) return;

        final pickedFile = result.files.first;
        fileName = pickedFile.name;
        fileExtension = fileName.split('.').last.toLowerCase();

        if (kIsWeb) {
          file = pickedFile.bytes;
        } else {
          if (pickedFile.bytes != null) {
            LoggerService.info(
              'Arquivo de documentos (mobile) usando bytes (${pickedFile.bytes!.length} bytes)',
            );
            file = pickedFile.bytes!;
          } else if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
            LoggerService.info(
              'Arquivo de documentos com path: ${pickedFile.path}',
            );
            file = File(pickedFile.path!);
          } else {
            LoggerService.error(
              'Nenhum path ou bytes disponíveis para o arquivo selecionado',
            );
            throw Exception(
              'Não foi possível acessar o arquivo selecionado. Tente novamente.',
            );
          }
        }
      }

      LoggerService.info('Verificando se arquivo é suportado...');
      if (!StorageService.isSupportedFile(fileName)) {
        LoggerService.error('Tipo de arquivo não suportado: $fileName');
        throw Exception(
          'Tipo de arquivo não suportado. Use apenas imagens (JPG, PNG, etc.) ou PDF.',
        );
      }
      LoggerService.info('Arquivo suportado, iniciando upload...');

      LoggerService.info('Checando conectividade com Firebase Storage...');
      final storageOk = await StorageService.checkStorageConnection(
        transactionId: widget.transactionId,
      );
      if (!storageOk) {
        LoggerService.warning('Conectividade com Storage falhou');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Falha ao conectar ao Firebase Storage. Verifique CORS, regras e login.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      LoggerService.info(
        'Conectividade com Storage OK, prosseguindo com upload',
      );

      LoggerService.info('Chamando StorageService.uploadReceipt...');
      await StorageService.uploadReceipt(
        file: file,
        fileName: fileName,
        transactionId: widget.transactionId!,
        fileExtension: fileExtension,
      );
      LoggerService.info('Upload concluído com sucesso!');

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

      try {
        await StorageService.deleteLocalReceipt(receipt.url);
      } catch (e) {
        LoggerService.warning(
          'Falha ao remover documento de recibo no Firestore: $e',
        );
      }

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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (!widget.readOnly) ...[
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
                Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Nenhum recibo adicionado',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

class ReceiptViewerScreen extends StatefulWidget {
  final ReceiptInfo receipt;

  const ReceiptViewerScreen({super.key, required this.receipt});

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  String? _base64Data;
  String? _transactionId;
  bool _isLoading = true;
  String? _errorMessage;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _loadReceiptData();
  }

  String _normalizeBase64(String input) {
    String cleaned = input.trim();
    final commaIndex = cleaned.indexOf(',');
    if (commaIndex != -1 &&
        cleaned.substring(0, commaIndex).toLowerCase().contains('base64')) {
      cleaned = cleaned.substring(commaIndex + 1);
    }
    cleaned = cleaned.replaceAll(RegExp(r"\s"), '');

    cleaned = cleaned.replaceAll('-', '+').replaceAll('_', '/');

    final mod = cleaned.length % 4;
    if (mod != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - mod), '=');
    }

    return cleaned;
  }

  Future<void> _loadReceiptData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        LoggerService.info(
          'ReceiptViewer: iniciando carregamento id=${widget.receipt.url}, fileName=${widget.receipt.name}, contentType=${widget.receipt.contentType}, isImage=${widget.receipt.isImage}',
        );
      } catch (_) {}

      final receiptData = await StorageService.getLocalReceipt(
        widget.receipt.url,
        fileName: widget.receipt.name,
      );

      if (receiptData != null) {
        final txnId = receiptData['transactionId'] as String?;
        final dlUrl = receiptData['downloadUrl'] as String?;
        setState(() {
          _transactionId = txnId;
          _downloadUrl = dlUrl ?? _downloadUrl;
        });

        if (receiptData['base64Data'] != null) {
          setState(() {
            _base64Data = receiptData['base64Data'];
            _isLoading = false;
          });
          try {
            final hasDataUri = _base64Data!.startsWith('data:');
            LoggerService.info(
              'ReceiptViewer: base64Length=${_base64Data!.length}, hasDataUri=$hasDataUri, isImage=${widget.receipt.isImage}, contentType=${widget.receipt.contentType}',
            );
          } catch (_) {}
        } else {
          try {
            LoggerService.warning(
              'ReceiptViewer: base64Data ausente; usando fallback de URL para exibição',
            );
          } catch (_) {}
          setState(() {
            _base64Data = null;
            _isLoading = false;
          });
        }
      } else {
        try {
          LoggerService.warning(
            'ReceiptViewer: recibo não encontrado no Firestore (receiptData null)',
          );
        } catch (_) {}
        setState(() {
          _errorMessage = 'Dados do recibo não encontrados';
          _isLoading = false;
        });
      }
    } catch (e) {
      try {
        LoggerService.error('ReceiptViewer: erro ao carregar recibo', e);
      } catch (_) {}
      setState(() {
        _errorMessage = 'Erro ao carregar recibo: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openInNewTab() async {
    try {
      String? url = _downloadUrl;
      if (url == null &&
          _transactionId != null &&
          widget.receipt.name.isNotEmpty) {
        url = await StorageService.getStorageDownloadUrl(
          transactionId: _transactionId!,
          fileName: widget.receipt.name,
        );
        if (url != null) {
          setState(() {
            _downloadUrl = url;
          });
        }
      }
      if (url == null) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        LoggerService.warning('Falha ao abrir em nova aba: $e');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receipt.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceiptData,
            tooltip: 'Recarregar',
          ),
          if (_downloadUrl != null || _transactionId != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInNewTab,
              tooltip: 'Abrir em nova aba',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReceiptData,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : Center(
              child: widget.receipt.isImage
                  ? InteractiveViewer(child: _buildImageFromBase64())
                  : _buildPdfViewer(),
            ),
    );
  }

  Widget _buildImageFromBase64() {
    if (_base64Data == null) {
      return _buildImageNetworkFallback();
    }

    try {
      final normalized = _normalizeBase64(_base64Data!);
      LoggerService.info(
        'ReceiptViewer: normalizedBase64Length=${normalized.length}',
      );
      final bytes = base64Decode(normalized);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Erro ao decodificar imagem'),
            ],
          );
        },
      );
    } catch (e) {
      LoggerService.error('ReceiptViewer: erro ao processar imagem', e);
      return _buildImageNetworkFallback(
        errorText: 'Erro ao processar imagem: $e',
      );
    }
  }

  Widget _buildPdfViewer() {
    if (kIsWeb) {
      try {
        LoggerService.info(
          'ReceiptViewer: web detectado, usando fallback de URL para PDF',
        );
      } catch (_) {}
      return _buildPdfNetworkFallback();
    }

    if (_base64Data == null) {
      return _buildPdfNetworkFallback();
    }

    try {
      final normalized = _normalizeBase64(_base64Data!);
      LoggerService.info(
        'ReceiptViewer: normalizedPdfBase64Length=${normalized.length}',
      );
      final bytes = base64Decode(normalized);
      return SfPdfViewer.memory(bytes);
    } catch (e) {
      LoggerService.error('ReceiptViewer: erro ao processar PDF', e);
      return _buildPdfNetworkFallback(errorText: 'Erro ao processar PDF: $e');
    }
  }

  Widget _buildPdfNetworkFallback({String? errorText}) {
    if (_transactionId == null || widget.receipt.name.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorText ?? 'Dados do PDF não disponíveis'),
        ],
      );
    }

    return FutureBuilder<String?>(
      future: StorageService.getStorageDownloadUrl(
        transactionId: _transactionId!,
        fileName: widget.receipt.name,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final url = snapshot.data;
        if (url == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorText ?? 'Não foi possível obter URL do PDF'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openInNewTab,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir em nova aba'),
              ),
            ],
          );
        }
        LoggerService.info('ReceiptViewer: usando fallback URL para PDF');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_downloadUrl == null) {
            setState(() {
              _downloadUrl = url;
            });
          }
        });
        return SfPdfViewer.network(url);
      },
    );
  }

  Widget _buildImageNetworkFallback({String? errorText}) {
    if (_transactionId == null || widget.receipt.name.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorText ?? 'Dados da imagem não disponíveis'),
        ],
      );
    }

    return FutureBuilder<String?>(
      future: StorageService.getStorageDownloadUrl(
        transactionId: _transactionId!,
        fileName: widget.receipt.name,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final url = snapshot.data;
        if (url == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorText ?? 'Não foi possível obter URL da imagem'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openInNewTab,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir em nova aba'),
              ),
            ],
          );
        }
        LoggerService.info('ReceiptViewer: usando fallback URL para imagem');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_downloadUrl == null) {
            setState(() {
              _downloadUrl = url;
            });
          }
        });
        return Image.network(url, fit: BoxFit.contain);
      },
    );
  }
}
