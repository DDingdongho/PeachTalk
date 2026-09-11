import 'package:flutter/material.dart';

import '../services/app_config_loader.dart';
import '../utils/color_utils.dart';
import 'character_select_screen.dart';

/// Content and styling for [SplashScreen], loaded from
/// `assets/data/splash_screen.json` so it can be edited without touching code.
class _SplashConfig {
  const _SplashConfig({
    required this.loadingText,
    required this.peachImage,
    required this.backgroundColor,
    required this.loadingTextColor,
    required this.progressColor,
    required this.progressTrackColor,
    required this.loadingDuration,
  });

  final String loadingText;
  final String peachImage;
  final Color backgroundColor;
  final Color loadingTextColor;
  final Color progressColor;
  final Color progressTrackColor;
  final Duration loadingDuration;

  factory _SplashConfig.fromJson(Map<String, dynamic> json) {
    return _SplashConfig(
      loadingText: json['loadingText'] as String,
      peachImage: json['peachImage'] as String,
      backgroundColor: colorFromHex(json['backgroundColor'] as String),
      loadingTextColor: colorFromHex(json['loadingTextColor'] as String),
      progressColor: colorFromHex(json['progressColor'] as String),
      progressTrackColor: colorFromHex(json['progressTrackColor'] as String),
      loadingDuration: Duration(milliseconds: json['loadingDurationMs'] as int),
    );
  }
}

/// The app's first screen: a peach logo over a progress bar shown while the
/// app initializes, then it hands off to [CharacterSelectScreen].
///
/// TODO: once there is real startup work (loading characters, checking
/// auth, etc.), replace the timed animation below with actual progress from
/// that work.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const _configPath = 'assets/data/splash_screen.json';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  Future<Map<String, dynamic>>? _configFuture;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this)
      ..addStatusListener(_handleProgressStatus);
    _configFuture = AppConfigLoader.load(SplashScreen._configPath);
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CharacterSelectScreen()),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(
            color: Colors.white,
            child: SizedBox.expand(),
          );
        }

        final config = _SplashConfig.fromJson(snapshot.data!);

        if (!_progressController.isAnimating &&
            _progressController.value == 0) {
          _progressController.duration = config.loadingDuration;
          _progressController.forward();
        }

        return Scaffold(
          backgroundColor: config.backgroundColor,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(config.peachImage, width: 180, height: 180),
                    const SizedBox(height: 40),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            minHeight: 8,
                            backgroundColor: config.progressTrackColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              config.progressColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      config.loadingText,
                      style: TextStyle(
                        color: config.loadingTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
