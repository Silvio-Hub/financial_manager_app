import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as app_models;
import '../providers/financial_provider.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';
import '../widgets/receipt_upload_widget.dart';
import '../widgets/radio_group.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final app_models.Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  app_models.TransactionType _selectedType = app_models.TransactionType.expense;
  app_models.TransactionCategory _selectedCategory =
      app_models.TransactionCategory.otherExpense;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  bool get _isEditing => widget.transaction != null;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadTransactionData();
      _transactionId = widget.transaction!.id;
    }
  }

  void _loadTransactionData() {
    final transaction = widget.transaction!;
    _titleController.text = transaction.title;
    _descriptionController.text = transaction.description;
    _amountController.text = Formatters.formatNumber(transaction.amount);
    _selectedType = transaction.type;
    _selectedCategory = transaction.category;
    _selectedDate = transaction.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onTypeChanged(app_models.TransactionType? type) {
    if (type != null) {
      setState(() {
        _selectedType = type;
        _selectedCategory = type == app_models.TransactionType.income
            ? app_models.TransactionCategory.salary
            : app_models.TransactionCategory.otherExpense;
      });
    }
  }

  List<app_models.TransactionCategory> _getAvailableCategories() {
    if (_selectedType == app_models.TransactionType.income) {
      return [
        app_models.TransactionCategory.salary,
        app_models.TransactionCategory.freelance,
        app_models.TransactionCategory.investment,
        app_models.TransactionCategory.gift,
        app_models.TransactionCategory.otherIncome,
      ];
    } else {
      return [
        app_models.TransactionCategory.food,
        app_models.TransactionCategory.transport,
        app_models.TransactionCategory.housing,
        app_models.TransactionCategory.entertainment,
        app_models.TransactionCategory.health,
        app_models.TransactionCategory.education,
        app_models.TransactionCategory.shopping,
        app_models.TransactionCategory.bills,
        app_models.TransactionCategory.otherExpense,
      ];
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = Formatters.parseDouble(_amountController.text) ?? 0.0;

      final transaction = app_models.Transaction(
        id: _isEditing
            ? widget.transaction!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        date: _selectedDate,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );

      final provider = context.read<FinancialProvider>();

      if (_isEditing) {
        await provider.updateTransactionWithSync(transaction);
      } else {
        await provider.addTransactionWithSync(transaction);
        setState(() {
          _transactionId = transaction.id;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Transação atualizada com sucesso!'
                  : 'Transação adicionada com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (_isEditing) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar transação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Transação' : 'Nova Transação'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTransaction,
              child: Text(
                _isEditing ? 'SALVAR' : 'ADICIONAR',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Transação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomRadioGroup<app_models.TransactionType>(
                        groupValue: _selectedType,
                        onChanged: _onTypeChanged,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Receita'),
                                leading:
                                    RadioButton<app_models.TransactionType>(
                                      value: app_models.TransactionType.income,
                                    ),
                                contentPadding: EdgeInsets.zero,
                                onTap: () => _onTypeChanged(
                                  app_models.TransactionType.income,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('Despesa'),
                                leading:
                                    RadioButton<app_models.TransactionType>(
                                      value: app_models.TransactionType.expense,
                                    ),
                                contentPadding: EdgeInsets.zero,
                                onTap: () => _onTypeChanged(
                                  app_models.TransactionType.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex: Salário, Supermercado, etc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: Validators.validateTitle,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor *',
                  hintText: '0,00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [PtBrCurrencyInputFormatter()],
                validator: Validators.validateAmount,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<app_models.TransactionCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _getAvailableCategories().map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (app_models.TransactionCategory? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione uma categoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Detalhes adicionais sobre a transação',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.validateDescription,
              ),

              const SizedBox(height: 24),

              ReceiptUploadWidget(
                transactionId: _transactionId,
                readOnly: false,
              ),

              const SizedBox(height: 24),

              if (MediaQuery.of(context).size.width < 600)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_transactionId != null && !_isEditing)
                          ? () => Navigator.of(context).pop(true)
                          : _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _transactionId != null && !_isEditing
                                  ? 'CONCLUIR'
                                  : (_isEditing
                                        ? 'SALVAR ALTERAÇÕES'
                                        : 'ADICIONAR TRANSAÇÃO'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    if (_transactionId != null && !_isEditing) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'FINALIZAR SEM RECIBOS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
