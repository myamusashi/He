import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finansa_new/core/constants/app_colors.dart';
import 'package:finansa_new/core/database/database_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> _emotionData = [];
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _trendData = [];
  bool _isLoading = true;

  final Map<String, Color> _emotionColors = {
    '😄': const Color(0xFF43A047),
    '😊': const Color(0xFF66BB6A),
    '😐': const Color(0xFF9E9E9E),
    '😑': const Color(0xFF78909C),
    '😢': const Color(0xFF1E88E5),
    '😤': const Color(0xFFE53935),
    '😰': const Color(0xFFF57F17),
  };

  final Map<String, String> _emotionLabels = {
    '😄': 'Bahagia',
    '😊': 'Senang',
    '😐': 'Netral',
    '😑': 'Bosan',
    '😢': 'Sedih',
    '😤': 'Stres',
    '😰': 'Cemas',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final emotion = await DatabaseHelper.instance.getExpenseByEmotion();
    final category = await DatabaseHelper.instance.getExpenseByCategory();
    final trend = await DatabaseHelper.instance.getLast30DaysTransactions();
    setState(() {
      _emotionData = emotion;
      _categoryData = category;
      _trendData = trend;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        title: const Text('Analisis Keuangan'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightBanner(),
                    const SizedBox(height: 24),
                    _buildEmotionChart(),
                    const SizedBox(height: 24),
                    _buildCategoryChart(),
                    const SizedBox(height: 24),
                    _buildTrendChart(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Insight Banner ────────────────────────────────────────
  Widget _buildInsightBanner() {
    String insight = 'Mulai catat transaksi untuk melihat analisis emosi kamu!';
    String emoji = '💡';

    if (_emotionData.isNotEmpty) {
      final top = _emotionData.first;
      final label = _emotionLabels[top['emotion_type']] ?? top['emotion_type'];
      insight =
          'Kamu paling banyak mengeluarkan uang saat merasa $label ${top['emotion_type']}. Yuk, kenali polamu!';
      emoji = '🔍';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLavender,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grafik Emosi (Bar Chart) ──────────────────────────────
  Widget _buildEmotionChart() {
    return _buildCard(
      title: '😤 Pengeluaran per Emosi',
      child: _emotionData.isEmpty
          ? _buildEmptyState('Belum ada data pengeluaran')
          : SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      _emotionData
                          .map((e) => (e['total'] as num).toDouble())
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = _emotionData[groupIndex];
                        return BarTooltipItem(
                          '${item['emotion_type']}\nRp ${_formatAmount(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= _emotionData.length) return const Text('');
                          return Text(
                            _emotionData[idx]['emotion_type'],
                            style: const TextStyle(fontSize: 18),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _emotionData.asMap().entries.map((entry) {
                    final color =
                        _emotionColors[entry.value['emotion_type']] ??
                        AppColors.primaryPurple;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['total'] as num).toDouble(),
                          color: color,
                          width: 28,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  // ── Grafik Kategori (Pie Chart) ───────────────────────────
  Widget _buildCategoryChart() {
    return _buildCard(
      title: '🛍️ Pengeluaran per Kategori',
      child: _categoryData.isEmpty
          ? _buildEmptyState('Belum ada data kategori')
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: _categoryData.asMap().entries.map((entry) {
                        final colors = [
                          AppColors.primaryPurple,
                          AppColors.secondaryPurple,
                          AppColors.incomeGreen,
                          AppColors.expenseRed,
                          AppColors.warningAmber,
                          const Color(0xFF1E88E5),
                          const Color(0xFF00ACC1),
                        ];
                        final color = colors[entry.key % colors.length];
                        final total = _categoryData
                            .map((e) => (e['total'] as num).toDouble())
                            .reduce((a, b) => a + b);
                        final pct =
                            ((entry.value['total'] as num).toDouble() /
                            total *
                            100);
                        return PieChartSectionData(
                          color: color,
                          value: (entry.value['total'] as num).toDouble(),
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _categoryData.asMap().entries.map((entry) {
                    final colors = [
                      AppColors.primaryPurple,
                      AppColors.secondaryPurple,
                      AppColors.incomeGreen,
                      AppColors.expenseRed,
                      AppColors.warningAmber,
                      const Color(0xFF1E88E5),
                      const Color(0xFF00ACC1),
                    ];
                    final color = colors[entry.key % colors.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.value['icon']} ${entry.value['name']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  // ── Grafik Tren 30 Hari (Line Chart) ─────────────────────
  Widget _buildTrendChart() {
    return _buildCard(
      title: '📈 Tren Pengeluaran 30 Hari',
      child: _trendData.isEmpty
          ? _buildEmptyState('Belum ada data tren')
          : SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) => Text(
                          'H-${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildLineSpots(),
                      isCurved: true,
                      color: AppColors.primaryPurple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryPurple.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<FlSpot> _buildLineSpots() {
    final Map<int, double> dailyExpense = {};
    for (final t in _trendData) {
      if (t['type'] == 'expense') {
        final date = DateTime.parse(t['date']);
        final daysAgo = DateTime.now().difference(date).inDays;
        dailyExpense[daysAgo] =
            (dailyExpense[daysAgo] ?? 0) + (t['amount'] as num).toDouble();
      }
    }
    if (dailyExpense.isEmpty) return [const FlSpot(0, 0)];
    return dailyExpense.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  // ── Helper Widgets ────────────────────────────────────────
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
    return amount.toStringAsFixed(0);
  }
}
