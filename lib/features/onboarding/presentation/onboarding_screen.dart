import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finansa_new/core/constants/app_colors.dart';
import 'package:finansa_new/features/auth/presentation/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'emoji': '💰',
      'title': 'Selamat Datang di FINANSA',
      'subtitle':
          'Aplikasi manajemen keuangan pribadi yang memahami perasaanmu',
      'desc':
          'Catat setiap transaksi dengan mudah dan kenali pola keuanganmu secara lebih dalam.',
      'color': const Color(0xFF4527A0),
      'bgColor': const Color(0xFFEDE7F6),
    },
    {
      'emoji': '😊',
      'title': 'Catat Emosi, Kenali Polamu',
      'subtitle': 'Setiap transaksi punya cerita emosi tersendiri',
      'desc':
          'Pilih emosimu saat bertransaksi — bahagia, stres, bosan, atau cemas. FINANSA akan menganalisis polamu.',
      'color': const Color(0xFF1565C0),
      'bgColor': const Color(0xFFE3F2FD),
    },
    {
      'emoji': '📊',
      'title': 'Analisis yang Bermakna',
      'subtitle': 'Lihat hubungan emosi dan pengeluaranmu',
      'desc':
          'Grafik interaktif membantu kamu memahami kapan dan mengapa kamu cenderung boros.',
      'color': const Color(0xFF2E7D32),
      'bgColor': const Color(0xFFE8F5E9),
    },
    {
      'emoji': '🔮',
      'title': 'Simulasi Masa Depan',
      'subtitle': 'Kecil terasa, besar dampaknya',
      'desc':
          'Lihat dampak jangka panjang dari kebiasaan pengeluaranmu dan mulai ambil keputusan finansial yang lebih bijak.',
      'color': const Color(0xFF6A1B9A),
      'bgColor': const Color(0xFFF3E5F5),
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),

          // Skip button
          Positioned(
            top: 52,
            right: 20,
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Container(
      color: page['bgColor'] as Color,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // Emoji illustration
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (page['color'] as Color).withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    page['emoji'] as String,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                page['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: page['color'] as Color,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                page['subtitle'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                page['desc'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: page['bgColor'] as Color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? page['color'] as Color
                      : (page['color'] as Color).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: page['color'] as Color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isLast ? 'Mulai Sekarang 🚀' : 'Selanjutnya',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
