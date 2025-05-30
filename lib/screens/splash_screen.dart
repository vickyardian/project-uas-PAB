// File: lib/screen/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_screen.dart';
// import 'home_screen.dart'; // Uncomment when HomeScreen is available

// Constants for better maintainability
class SplashConstants {
  static const Duration animationDuration = Duration(milliseconds: 2000);
  static const Duration splashDelay = Duration(seconds: 2);
  static const double tabletBreakpoint = 600;
  static const int floatingElementsCount = 20;

  // Animation intervals
  static const Interval fadeInterval = Interval(
    0.2,
    1.0,
    curve: Curves.easeInOut,
  );
  static const Interval slideInterval = Interval(
    0.3,
    1.0,
    curve: Curves.elasticOut,
  );
  static const Interval scaleInterval = Interval(
    0.0,
    0.8,
    curve: Curves.elasticOut,
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: SplashConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: SplashConstants.fadeInterval,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: SplashConstants.slideInterval,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: SplashConstants.scaleInterval,
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Show loading state
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Delay to show splash screen
      await Future.delayed(SplashConstants.splashDelay);

      // Check if user is already logged in
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (currentUser != null) {
          // User is logged in, navigate to home
          // TODO: Uncomment when HomeScreen is available
          // _navigateToHome();

          // Temporary: Navigate to AuthScreen for now
          _navigateToAuth();
        }
        // If not logged in, stay on splash screen and wait for user action
      }
    } catch (e) {
      // Handle Firebase Auth errors
      debugPrint('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to check authentication status';
        });
      }
    }
  }

  void _navigateToAuth() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // TODO: Uncomment when HomeScreen is available
  // void _navigateToHome() {
  //   if (!mounted) return;
  //
  //   Navigator.pushReplacement(
  //     context,
  //     PageRouteBuilder(
  //       pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         return FadeTransition(opacity: animation, child: child);
  //       },
  //       transitionDuration: const Duration(milliseconds: 500),
  //     ),
  //   );
  // }

  void _handleLoginButtonPress() {
    _navigateToAuth();
  }

  void _handleGuestButtonPress() {
    // TODO: Navigate to HomeScreen as guest when available
    // _navigateToHome();

    // Temporary: Navigate to AuthScreen for now
    _navigateToAuth();
  }

  void _retryAuthCheck() {
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > SplashConstants.tabletBreakpoint;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background elements
              RepaintBoundary(child: _buildAnimatedBackground(size)),

              // Main pizza illustration
              Positioned(
                top: isLandscape ? size.height * 0.05 : size.height * 0.08,
                right: isTablet ? -size.width * 0.15 : -size.width * 0.2,
                child: _buildPizzaIllustration(size, isTablet),
              ),

              // Floating ingredients with enhanced animation
              RepaintBoundary(child: _buildFloatingIngredients(size, isTablet)),

              // Content with enhanced layout
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildMainContent(isTablet, isLandscape),
              ),

              // Loading indicator
              if (_isLoading)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: _buildLoadingIndicator(),
                ),

              // Error message
              if (_errorMessage != null)
                Positioned(
                  bottom: 120,
                  left: 20,
                  right: 20,
                  child: _buildErrorMessage(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFFF6B35),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Checking authentication...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade300, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _retryAuthCheck,
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.red.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: List.generate(SplashConstants.floatingElementsCount, (
            index,
          ) {
            final offset =
                (_animationController.value * 2 * 3.14159) + (index * 0.3);
            return Positioned(
              left:
                  (size.width * 0.1) +
                  (index % 3) * (size.width * 0.3) +
                  (20 * (index % 2 == 0 ? 1 : -1) * _animationController.value),
              top:
                  (size.height * 0.1) +
                  (index % 4) * (size.height * 0.2) +
                  (15 * _animationController.value),
              child: Transform.rotate(
                angle: offset,
                child: Container(
                  width: 4 + (index % 3) * 2,
                  height: 4 + (index % 3) * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getBackgroundElementColor(index),
                    boxShadow: [
                      BoxShadow(
                        color: _getBackgroundElementColor(index, shadow: true),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Color _getBackgroundElementColor(int index, {bool shadow = false}) {
    const colors = [
      Color(0xFFFF6B35),
      Color(0xFFFFE66D),
      Color(0xFF4ECDC4),
      Colors.white,
    ];

    final color = colors[index % 4];
    return shadow ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.3);
  }

  Widget _buildPizzaIllustration(Size size, bool isTablet) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _animationController.value * 0.3,
            child: Container(
              width: isTablet ? size.width * 0.8 : size.width * 0.9,
              height: isTablet ? size.width * 0.8 : size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    const Color(0xFFFF6B35).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: isTablet ? size.width * 0.6 : size.width * 0.7,
                  height: isTablet ? size.width * 0.6 : size.width * 0.7,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/pizzaa.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingIngredients(Size size, bool isTablet) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top floating ingredients
            Positioned(
              top: size.height * 0.12 + (_animationController.value * 15),
              left: size.width * 0.08,
              child: _buildEnhancedFloatingIngredient(
                const Color(0xFFFF6B35),
                isTablet ? 14 : 10,
                _animationController.value * 2,
              ),
            ),
            Positioned(
              top: size.height * 0.18 + (_animationController.value * -10),
              left: size.width * 0.02,
              child: _buildEnhancedFloatingIngredient(
                const Color(0xFFFFE66D),
                isTablet ? 18 : 14,
                _animationController.value * -1.5,
              ),
            ),
            // Bottom floating ingredients
            Positioned(
              bottom: size.height * 0.35 + (_animationController.value * 20),
              right: size.width * 0.12,
              child: _buildEnhancedFloatingIngredient(
                const Color(0xFF4ECDC4),
                isTablet ? 16 : 12,
                _animationController.value * 1.8,
              ),
            ),
            Positioned(
              bottom: size.height * 0.42 + (_animationController.value * -8),
              right: size.width * 0.05,
              child: _buildEnhancedFloatingIngredient(
                const Color(0xFFFF8E53),
                isTablet ? 12 : 8,
                _animationController.value * -2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(bool isTablet, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 60 : 30,
        vertical: isTablet ? 40 : 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0f3460).withOpacity(0.8),
            const Color(0xFF0f3460),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildWelcomeText(isTablet),
            ),
          ),
          SizedBox(height: isTablet ? 50 : 40),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildActionButtons(isLandscape, isTablet),
            ),
          ),
          SizedBox(height: isTablet ? 30 : 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: isTablet ? 42 : 32, height: 1.2),
            children: const [
              TextSpan(
                text: 'Welcome to your\n',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              TextSpan(
                text: 'food ',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'paradise',
                style: TextStyle(
                  color: Color(0xFFFFE66D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 10),
        Text(
          'experience food\nperfection delivered',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.w300,
            height: 1.2,
          ),
        ),
        SizedBox(height: isTablet ? 40 : 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            'Shared and delightful, for an easy and enjoyable food ordering experience.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: isTablet ? 18 : 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isLandscape, bool isTablet) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Hide buttons while loading
    }

    return isLandscape && !isTablet
        ? Row(
          children: [
            Expanded(child: _buildLoginButton()),
            const SizedBox(width: 15),
            Expanded(child: _buildGuestButton()),
          ],
        )
        : Column(
          children: [
            _buildLoginButton(),
            const SizedBox(height: 15),
            _buildGuestButton(),
          ],
        );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleLoginButtonPress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Login / Signup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: _handleGuestButtonPress,
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Continue as Guest',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFloatingIngredient(
    Color color,
    double size,
    double rotation,
  ) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.7),
              color.withValues(alpha: 0.3),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}
