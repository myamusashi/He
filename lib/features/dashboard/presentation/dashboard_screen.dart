import 'package:flutter/material.dart';
import 'package:finansa_new/core/constants/app_colors.dart';
import 'package:finansa_new/core/services/firestore_service.dart';
import 'package:finansa_new/features/profile/presentation/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _summary = {
    'balance': 0.0,
    'income': 0.0,
    'expense': 0.0,
  };
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, int> _emotionCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Ambil data dari Firestore
      final summary = await FirestoreService.instance.getSummary();
      final transactions = await FirestoreService.instance.getTransactions();

      // Hitung emosi minggu ini
      final Map<String, int> emotionCounts = {};
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      for (final t in transactions) {
        try {
          final date = DateTime.parse(t['date']);
          if (date.isAfter(weekAgo) && t['emotion_type'] != null) {
            final emo = t['emotion_type'] as String;
            emotionCounts[emo] = (emotionCounts[emo] ?? 0) + 1;
          }
        } catch (_) {}
      }

      setState(() {
        _summary = summary;
        _recentTransactions = transactions.take(5).toList();
        _emotionCounts = emotionCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000)
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    if (amount >= 1000000)
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  String _getInsight() {
    if (_emotionCounts.isEmpty) {
      return 'Mulai catat transaksi pertamamu dan pilih emosimu saat itu!';
    }
    final topEmo =
        _emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final labels = {
      '😤': 'stres',
      '😢': 'sedih',
      '😰': 'cemas',
      '😄': 'bahagia',
      '😊': 'senang',
      '😐': 'netral',
      '😑': 'bosan',
    };
    final label = labels[topEmo.key] ?? 'tertentu';
    final isNegative = ['😤', '😢', '😰', '😑'].contains(topEmo.key);
    if (isNegative) {
      return 'Kamu paling sering bertransaksi saat $label ${topEmo.key}. Coba tarik nafas dulu sebelum belanja!';
    }
    return 'Kamu paling sering bertransaksi saat $label ${topEmo.key}. Pertahankan kebiasaan baikmu!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halo, Pengguna! 👋',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol refresh
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          // Icon Profile
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadData();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child:
                    Icon(Icons.person_outline, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primaryPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    _buildEmotionSummary(),
                    const SizedBox(height: 16),
                    _buildInsightCard(),
                    const SizedBox(height: 20),
                    _buildRecentTransactions(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Balance Card ──────────────────────────────────────────
  Widget _buildBalanceCard() {
    final balance = (_summary['balance'] as num).toDouble();
    final income = (_summary['income'] as num).toDouble();
    final expense = (_summary['expense'] as num).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _balanceItem(
                Icons.arrow_downward,
                'Pemasukan',
                income,
                AppColors.incomeGreen,
              ),
              const SizedBox(width: 24),
              _balanceItem(
                Icons.arrow_upward,
                'Pengeluaran',
                expense,
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceItem(
    IconData icon,
    String label,
    double amount,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              _formatAmount(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Emotion Summary ───────────────────────────────────────
  Widget _buildEmotionSummary() {
    final emotions = [
      {'emoji': '😄', 'label': 'Bahagia'},
      {'emoji': '😊', 'label': 'Senang'},
      {'emoji': '😐', 'label': 'Netral'},
      {'emoji': '😤', 'label': 'Stres'},
      {'emoji': '😢', 'label': 'Sedih'},
      {'emoji': '😰', 'label': 'Cemas'},
      {'emoji': '😑', 'label': 'Bosan'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emosi Minggu Ini',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: emotions.map((e) {
              final count = _emotionCounts[e['emoji']] ?? 0;
              return Column(
                children: [
                  Text(
                    e['emoji']!,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: count > 0
                          ? AppColors.primaryPurple
                          : Colors.grey.shade300,
                    ),
                  ),
                  Text(
                    e['label']!,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Insight Card ──────────────────────────────────────────
  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLavender,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondaryPurple.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getInsight(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Transactions ───────────────────────────────────
  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _loadData,
              child: const Text(
                'Refresh',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Text('🧾', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap tombol + untuk mulai mencatat',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_recentTransactions.map((t) => _buildTxItem(t))),
      ],
    );
  }

  Widget _buildTxItem(Map<String, dynamic> t) {
    final isIncome = t['type'] == 'income';
    final amount = (t['amount'] as num).toDouble();
    final icon = t['category_icon'] ?? '💸';
    final catName = t['category_name'] ?? 'Lainnya';
    final emotion = t['emotion_type'] ?? '';
    final note = t['note'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon kategori
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.incomeGreen.withOpacity(0.1)
                  : AppColors.expenseRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      catName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (emotion.isNotEmpty)
                      Text(emotion, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Nominal
          Text(
            '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
            ),
          ),
        ],
      ),
    );
  }
}
