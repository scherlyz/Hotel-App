import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/splash_hotel.jpg', // Ganti jika assets di root
              fit: BoxFit.cover,
            ),
          ),

          /// Dark Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.25),
                    Colors.black.withOpacity(.35),
                    Colors.black.withOpacity(.55),
                    Colors.black.withOpacity(.75),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 40),

                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                          children: [

                            const TextSpan(
                              text: "Connect\nWith\nThe ",
                            ),

                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1F8A70),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "StayMap",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const TextSpan(
                              text: "\nJourney",
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [

                          Expanded(
                            child: Text(
                              "Discover the best hotels around you.\nFind your perfect stay quickly\nand comfortably.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.95),
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          InkWell(
                            borderRadius: BorderRadius.circular(100),
                            onTap: _goToLogin,
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(.45),
                                    blurRadius: 25,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "START",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}