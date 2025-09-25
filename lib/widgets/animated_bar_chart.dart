import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/financial_summary.dart' as models;

class AnimatedBarChart extends StatefulWidget {
  final List<models.PieChartData> categoryData;
  final String title;
  final double height;
  final bool isExpense;

  const AnimatedBarChart({
    super.key,
    required this.categoryData,
    required this.title,
    this.height = 300,
    this.isExpense = true,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  widget.isExpense ? Icons.trending_down : Icons.trending_up,
                  color: widget.isExpense ? Colors.red : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY() * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: _buildTooltipItem,
                        ),
                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                barTouchResponse == null ||
                                barTouchResponse.spot == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                          });
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
                            getTitlesWidget: _buildBottomTitles,
                            reservedSize: 42,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: _calculateInterval(),
                            getTitlesWidget: _buildLeftTitles,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      barGroups: _buildBarGroups(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
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

  List<BarChartGroupData> _buildBarGroups() {
    return widget.categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value * _animation.value,
            color: data.color,
            width: isTouched ? 25 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY() * 1.2,
              color: data.color.withValues(alpha: 0.1),
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    }).toList();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= 0 && value.toInt() < widget.categoryData.length) {
      final category = widget.categoryData[value.toInt()].label;
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Transform.rotate(
          angle: -0.5,
          child: Text(
            _getShortCategoryName(category),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
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

  BarTooltipItem? _buildTooltipItem(
    BarChartGroupData group,
    int groupIndex,
    BarChartRodData rod,
    int rodIndex,
  ) {
    if (groupIndex >= 0 && groupIndex < widget.categoryData.length) {
      final data = widget.categoryData[groupIndex];
      return BarTooltipItem(
        '${data.label}\\n${_formatCurrency(data.value)}\\n${data.percentage.toStringAsFixed(1)}%',
        TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }
    return null;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.categoryData.map<Widget>((models.PieChartData data) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: data.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${data.percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma categoria encontrada',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    if (widget.categoryData.isEmpty) return 100;
    return widget.categoryData
        .map<double>((models.PieChartData data) => data.value)
        .reduce((a, b) => a > b ? a : b);
  }

  double _calculateInterval() {
    final maxY = _getMaxY();
    return maxY / 5; // 5 linhas de grade
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  String _getShortCategoryName(String category) {
    // Mapear nomes longos para versões curtas
    final shortNames = {
      'Alimentação': 'Comida',
      'Transporte': 'Transp.',
      'Entretenimento': 'Entret.',
      'Saúde': 'Saúde',
      'Educação': 'Educ.',
      'Compras': 'Compras',
      'Outros': 'Outros',
      'Salário': 'Salário',
      'Freelance': 'Freela',
      'Investimentos': 'Invest.',
      'Vendas': 'Vendas',
    };
    
    return shortNames[category] ?? category;
  }
}