import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/financial_summary.dart';

class AnimatedLineChart extends StatefulWidget {
  final List<MonthlyData> monthlyData;
  final String title;
  final double height;
  final VoidCallback? onAddTransaction;
  final bool yearly;
  final bool showGranularityToggle;

  const AnimatedLineChart({
    super.key,
    required this.monthlyData,
    required this.title,
    this.height = 300,
    this.onAddTransaction,
    this.yearly = false,
    this.showGranularityToggle = true,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool showIncome = true;
  bool showExpense = true;
  bool showBalance = true;
  bool _isYearly = false;
  int? _selectedYear;
  static const List<String> _monthLabels = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  List<MonthlyData> get _dataPoints {
    if (!_isYearly) return widget.monthlyData;

    final int year = _selectedYear ??
        (widget.monthlyData.isNotEmpty
            ? widget.monthlyData.last.month.year
            : DateTime.now().year);

    final Map<int, MonthlyData> byMonth = {
      for (final m
          in widget.monthlyData.where((e) => e.month.year == year))
        m.month.month: m,
    };

    final List<MonthlyData> fullYear = [];
    for (int month = 1; month <= 12; month++) {
      final existing = byMonth[month];
      if (existing != null) {
        fullYear.add(existing);
      } else {
        fullYear.add(
          MonthlyData(
            month: DateTime(year, month, 1),
            income: 0,
            expense: 0,
            balance: 0,
          ),
        );
      }
    }
    return fullYear;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
    _isYearly = widget.yearly;
    _selectedYear = widget.monthlyData.isNotEmpty
        ? widget.monthlyData.last.month.year
        : DateTime.now().year;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShowEmptyState()) {
      return _buildEmptyState();
    }

    final bars = _buildLineBarsData();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobileLike = constraints.maxWidth < 420;

                final Widget titleWidget = Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                );

                final Widget controls = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.showGranularityToggle) _buildGranularityToggle(),
                    _buildLegendToggle(),
                  ],
                );

                if (isMobileLike) {
                  // Em dispositivos móveis (ou largura estreita), colocar os botões abaixo do título
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 8),
                      controls,
                    ],
                  );
                }

                // Em telas maiores, manter título e controles lado a lado
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: titleWidget),
                    controls,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: _buildBottomTitles,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateInterval(),
                            reservedSize: 60,
                            getTitlesWidget: _buildLeftTitles,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          left: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      minX: 0,
                      maxX: _dataPoints.isEmpty
                          ? 11
                          : (_dataPoints.length - 1).toDouble(),
                      minY: _getMinY(),
                      maxY: _getMaxY(),
                      lineBarsData: bars,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: _buildTooltipItems,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lines = [];

    if (showIncome) {
      lines.add(
        LineChartBarData(
          spots: _dataPoints.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.income);
          }).toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (showExpense) {
      lines.add(
        LineChartBarData(
          spots: _dataPoints.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.expense);
          }).toList(),
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (showBalance) {
      lines.add(
        LineChartBarData(
          spots: _dataPoints.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.balance);
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          dashArray: [5, 5],
        ),
      );
    }

    return lines;
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (_dataPoints.isEmpty) {
      if (index >= 0 && index < 12) {
        return SideTitleWidget(
          axisSide: meta.axisSide,
          child: Text(
            _monthLabels[index],
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }
      return const SizedBox.shrink();
    }
    if (index >= 0 && index < _dataPoints.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          _dataPoints[index].monthName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        _formatCurrency(value),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  List<LineTooltipItem> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      final monthData = _dataPoints[touchedSpot.x.toInt()];
      String label = '';
      Color color = Colors.black;

      if (touchedSpot.barIndex == 0 && showIncome) {
        label = 'Receita: ${_formatCurrency(monthData.income)}';
        color = Colors.green;
      } else if ((touchedSpot.barIndex == 1 && showIncome && showExpense) ||
          (touchedSpot.barIndex == 0 && !showIncome && showExpense)) {
        label = 'Despesa: ${_formatCurrency(monthData.expense)}';
        color = Colors.red;
      } else {
        label = 'Saldo: ${_formatCurrency(monthData.balance)}';
        color = Colors.blue;
      }

      return LineTooltipItem(
        '${monthData.monthName}\\n$label',
        TextStyle(color: color, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Widget _buildLegendToggle() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'income':
              showIncome = !showIncome;
              break;
            case 'expense':
              showExpense = !showExpense;
              break;
            case 'balance':
              showBalance = !showBalance;
              break;
          }
        });
        _animationController.reset();
        _animationController.forward();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'income',
          child: Row(
            children: [
              Icon(
                showIncome ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('Receitas'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'expense',
          child: Row(
            children: [
              Icon(
                showExpense ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Despesas'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'balance',
          child: Row(
            children: [
              Icon(
                showBalance ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('Saldo'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showIncome)
          _buildLegendItem('Receitas', Colors.green, Icons.trending_up),
        if (showExpense)
          _buildLegendItem('Despesas', Colors.red, Icons.trending_down),
        if (showBalance)
          _buildLegendItem('Saldo', Colors.blue, Icons.account_balance),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Determina quando mostrar o estado vazio (sem dados do usuário)
  bool _shouldShowEmptyState() {
    if (widget.monthlyData.isEmpty) return true;
    final hasIncome = widget.monthlyData.any((m) => m.income != 0);
    final hasExpense = widget.monthlyData.any((m) => m.expense != 0);
    final hasBalance = widget.monthlyData.any((m) => m.balance != 0);
    return !(hasIncome || hasExpense || hasBalance);
  }

  // Estado vazio consistente com outros gráficos
  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dado disponível',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione algumas transações para ver os gráficos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (widget.onAddTransaction != null)
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar transação'),
                ),
              ),
          ],
        ),
      ),
    );
  }
 
  // _buildEmptyState removido por não ser mais utilizado

  double _getMinY() {
    if (_dataPoints.isEmpty) return 0;

    double min = 0;
    for (final data in _dataPoints) {
      if (showBalance && data.balance < min) min = data.balance;
    }
    return min * 1.1;
  }

  double _getMaxY() {
    if (_dataPoints.isEmpty) return 100;

    double max = 0;
    for (final data in _dataPoints) {
      if (showIncome && data.income > max) max = data.income;
      if (showExpense && data.expense > max) max = data.expense;
      if (showBalance && data.balance > max) max = data.balance;
    }

    // Evita range Y nulo quando todos os valores são zero
    final expandedMax = max * 1.1;
    if (expandedMax <= 0) {
      return 10; // range mínimo para que o gráfico apareça
    }
    return expandedMax;
  }

  double _calculateInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 0) {
      return 1;
    }
    return range / 5;
  }

  String _formatCurrency(double value) {
    if (value.abs() >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  Widget _buildGranularityToggle() {
    return ToggleButtons(
      isSelected: [_isYearly == false, _isYearly == true],
      onPressed: (index) {
        setState(() {
          _isYearly = index == 1;
        });
        _animationController
          ..reset()
          ..forward();
      },
      constraints: const BoxConstraints(minHeight: 32, minWidth: 64),
      borderRadius: BorderRadius.circular(8),
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Mensal')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Anual')),
      ],
    );
  }
}

// Modo anual exibe meses Jan–Dez do ano selecionado
