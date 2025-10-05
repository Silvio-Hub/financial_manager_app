import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  // Receitas
  salary,
  freelance,
  investment,
  gift,
  otherIncome,

  // Despesas
  food,
  transport,
  housing,
  entertainment,
  health,
  education,
  shopping,
  bills,
  otherExpense,
}

class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? userId;
  final List<String> receiptUrls;

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.userId,
    this.receiptUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'receiptUrls': receiptUrls,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: (() {
        final raw = (map['type'] ?? '').toString().toLowerCase().trim();
        if (raw == 'income' || raw == 'receita' || raw == 'entrada') {
          return TransactionType.income;
        }
        if (raw == 'expense' ||
            raw == 'despesa' ||
            raw == 'saida' ||
            raw == 'saída') {
          return TransactionType.expense;
        }
        return TransactionType.expense;
      })(),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.otherExpense,
      ),
      date: (() {
        final raw = map['date'];
        if (raw is Timestamp) return raw.toDate();
        if (raw is String && raw.isNotEmpty) {
          return DateTime.parse(raw);
        }
        return DateTime.now();
      })(),
      userId: map['userId'],
      receiptUrls: List<String>.from(map['receiptUrls'] ?? []),
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? userId,
    List<String>? receiptUrls,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      receiptUrls: receiptUrls ?? this.receiptUrls,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, type: $type, category: $category, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Receita';
      case TransactionType.expense:
        return 'Despesa';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.expense:
        return Icons.arrow_downward;
    }
  }
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      // Receitas
      case TransactionCategory.salary:
        return 'Salário';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.investment:
        return 'Investimento';
      case TransactionCategory.gift:
        return 'Presente';
      case TransactionCategory.otherIncome:
        return 'Outras Receitas';

      // Despesas
      case TransactionCategory.food:
        return 'Alimentação';
      case TransactionCategory.transport:
        return 'Transporte';
      case TransactionCategory.housing:
        return 'Moradia';
      case TransactionCategory.entertainment:
        return 'Entretenimento';
      case TransactionCategory.health:
        return 'Saúde';
      case TransactionCategory.education:
        return 'Educação';
      case TransactionCategory.shopping:
        return 'Compras';
      case TransactionCategory.bills:
        return 'Contas';
      case TransactionCategory.otherExpense:
        return 'Outras Despesas';
    }
  }

  IconData get icon {
    switch (this) {
      // Receitas
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.freelance:
        return Icons.laptop;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.gift:
        return Icons.card_giftcard;
      case TransactionCategory.otherIncome:
        return Icons.attach_money;

      // Despesas
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.housing:
        return Icons.home;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.health:
        return Icons.local_hospital;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.bills:
        return Icons.receipt;
      case TransactionCategory.otherExpense:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      // Receitas
      case TransactionCategory.salary:
        return Colors.green;
      case TransactionCategory.freelance:
        return Colors.blue;
      case TransactionCategory.investment:
        return Colors.purple;
      case TransactionCategory.gift:
        return Colors.pink;
      case TransactionCategory.otherIncome:
        return Colors.teal;

      // Despesas
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.transport:
        return Colors.red;
      case TransactionCategory.housing:
        return Colors.brown;
      case TransactionCategory.entertainment:
        return Colors.indigo;
      case TransactionCategory.health:
        return Colors.cyan;
      case TransactionCategory.education:
        return Colors.amber;
      case TransactionCategory.shopping:
        return Colors.deepPurple;
      case TransactionCategory.bills:
        return Colors.grey;
      case TransactionCategory.otherExpense:
        return Colors.blueGrey;
    }
  }
}
