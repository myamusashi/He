import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finansa_new/core/constants/app_colors.dart';
import 'package:finansa_new/core/database/database_helper.dart';
import 'package:finansa_new/features/onboarding/presentation/onboarding_screen.dart';
import 'package:finansa_new/core/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Pengguna';
  String _currency = 'IDR';
  bool _darkMode = false;
  bool _notif = true;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadStats();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Pengguna';
      _currency = prefs.getString('currency') ?? 'IDR';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notif = prefs.getBool('notif_enabled') ?? true;
    });
    _nameController.text = _name;
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final summary = await DatabaseHelper.instance.getSummary();
    final transactions = await DatabaseHelper.instance.getAllTransactions();
    final goals = await DatabaseHelper.instance.getAllGoals();
    setState(() {
      _stats = {
        'balance': summary['balance'],
        'income': summary['income'],
        'expense': summary['expense'],
        'tx_count': transactions.length,
        'goals_count': goals.length,
        'goals_done': goals
            .where(
              (g) =>
                  (g['current_amount'] as num) >= (g['target_amount'] as num),
            )
            .length,
      };
      _isLoading = false;
    });
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    setState(() => _name = _nameController.text);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('notif_enabled', _notif);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000)
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        title: const Text('Profil & Pengaturan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildSettingsSection(),
                  const SizedBox(height: 16),
                  _buildDangerSection(),
                  const SizedBox(height: 32),
                  _buildAppInfo(),
                ],
              ),
            ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pengguna FINANSA',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditNameDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Card ────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Keuangan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  '💰',
                  'Total Saldo',
                  _formatAmount((_stats['balance'] as num?)?.toDouble() ?? 0),
                  AppColors.primaryPurple,
                ),
              ),
              Expanded(
                child: _statItem(
                  '📈',
                  'Pemasukan',
                  _formatAmount((_stats['income'] as num?)?.toDouble() ?? 0),
                  AppColors.incomeGreen,
                ),
              ),
              Expanded(
                child: _statItem(
                  '📉',
                  'Pengeluaran',
                  _formatAmount((_stats['expense'] as num?)?.toDouble() ?? 0),
                  AppColors.expenseRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  '🧾',
                  'Transaksi',
                  '${_stats['tx_count'] ?? 0}x',
                  AppColors.secondaryPurple,
                ),
              ),
              Expanded(
                child: _statItem(
                  '🎯',
                  'Total Goal',
                  '${_stats['goals_count'] ?? 0}',
                  AppColors.warningAmber,
                ),
              ),
              Expanded(
                child: _statItem(
                  '✅',
                  'Goal Selesai',
                  '${_stats['goals_done'] ?? 0}',
                  AppColors.incomeGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── Settings Section ──────────────────────────────────────
  Widget _buildSettingsSection() {
    return Container(
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
      child: Column(
        children: [
          _sectionHeader('⚙️ Pengaturan'),

          _switchTile(
            icon: Icons.notifications_outlined,
            label: 'Notifikasi Pengingat',
            subtitle: 'Ingatkan mencatat transaksi jam 20:00',
            value: _notif,
            onChanged: (val) async {
              setState(() => _notif = val);

              await _savePrefs();

              if (val) {
                await NotificationService.instance.scheduleDailyReminder(
                  hour: 20,
                  minute: 0,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengingat harian aktif jam 20:00'),
                      backgroundColor: AppColors.primaryPurple,
                    ),
                  );
                }
              } else {
                await NotificationService.instance.cancelAll();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengingat harian dimatikan'),
                      backgroundColor: AppColors.expenseRed,
                    ),
                  );
                }
              }
            },
          ),

          _divider(),

          _switchTile(
            icon: Icons.dark_mode_outlined,
            label: 'Mode Gelap',
            subtitle: 'Tampilan gelap (segera hadir)',
            value: _darkMode,
            onChanged: (val) {
              setState(() => _darkMode = val);
              _savePrefs();
            },
          ),

          _divider(),

          _settingTile(
            icon: Icons.attach_money_outlined,
            label: 'Mata Uang',
            subtitle: _currency,
            onTap: _showCurrencyDialog,
          ),

          _divider(),

          _settingTile(
            icon: Icons.info_outline,
            label: 'Lihat Onboarding Lagi',
            subtitle: 'Tampilkan panduan awal',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),

          _divider(),

          _settingTile(
            icon: Icons.notifications_active_outlined,
            label: 'Test Notifikasi',
            subtitle: 'Kirim notifikasi percobaan sekarang',
            onTap: () async {
              await NotificationService.instance.showTestNotification();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifikasi terkirim! Cek status bar HP kamu.',
                    ),
                    backgroundColor: AppColors.primaryPurple,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Danger Section ────────────────────────────────────────
  Widget _buildDangerSection() {
    return Container(
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
      child: Column(
        children: [
          _sectionHeader('⚠️ Zona Berbahaya'),
          _settingTile(
            icon: Icons.delete_sweep_outlined,
            label: 'Hapus Semua Transaksi',
            subtitle: 'Data tidak dapat dipulihkan',
            color: AppColors.expenseRed,
            onTap: _confirmDeleteAllTransactions,
          ),
          _divider(),
          _settingTile(
            icon: Icons.restore_outlined,
            label: 'Reset Semua Data',
            subtitle: 'Hapus semua data termasuk goals dan budget',
            color: AppColors.expenseRed,
            onTap: _confirmResetAll,
          ),
        ],
      ),
    );
  }

  // ── App Info ──────────────────────────────────────────────
  Widget _buildAppInfo() {
    return Column(
      children: [
        const Text(
          'FINANSA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Versi 1.0.0',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Aplikasi Manajemen Keuangan Berbasis Psikologi Finansial',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2025 FINANSA • Universitas Pamulang',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  // ── Helper Widgets ────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16);

  Widget _switchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLavender,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryPurple, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryPurple,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String label,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color != null
              ? color.withOpacity(0.1)
              : AppColors.surfaceLavender,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primaryPurple, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.textSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────
  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Masukkan nama kamu'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveName();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    final currencies = ['IDR', 'USD', 'SGD', 'MYR', 'EUR'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Mata Uang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies
              .map(
                (c) => RadioListTile<String>(
                  value: c,
                  groupValue: _currency,
                  title: Text(c),
                  activeColor: AppColors.primaryPurple,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('currency', val!);
                    setState(() => _currency = val);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _confirmDeleteAllTransactions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Transaksi?'),
        content: const Text(
          'Seluruh data transaksi akan dihapus permanen dan tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('transactions');
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua transaksi telah dihapus'),
                    backgroundColor: AppColors.expenseRed,
                  ),
                );
                _loadStats();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmResetAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Semua Data?'),
        content: const Text(
          'Semua data termasuk transaksi, goals, dan budget akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('transactions');
              await db.delete('goals');
              await db.update('categories', {'budget_limit': 0});
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_name');
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua data telah direset'),
                    backgroundColor: AppColors.expenseRed,
                  ),
                );
                _loadPrefs();
                _loadStats();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
