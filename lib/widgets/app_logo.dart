import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  
  const AppLogo({
    Key? key,
    this.size = 50.0,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppStyles.blueGradient,
        shape: BoxShape.circle,
        boxShadow: showShadow ? [
          BoxShadow(
            color: AppStyles.primaryColor.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          'B',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.55,
          ),
        ),
      ),
    );
  }
}

class AnimatedAppLogo extends StatefulWidget {
  final double size;
  final bool showShadow;
  final bool animate;
  
  const AnimatedAppLogo({
    Key? key,
    this.size = 50.0,
    this.showShadow = true,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.animate) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: AppLogo(
          size: widget.size,
          showShadow: widget.showShadow,
        ),
      );
    } else {
      return AppLogo(
        size: widget.size,
        showShadow: widget.showShadow,
      );
    }
  }
} 