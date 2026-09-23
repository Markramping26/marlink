import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SosPressHoldButton extends StatefulWidget {
  final VoidCallback onActivated;
  final double size;

  const SosPressHoldButton({
    super.key,
    required this.onActivated,
    this.size = 140,
  });

  @override
  State<SosPressHoldButton> createState() => _SosPressHoldButtonState();
}

class _SosPressHoldButtonState extends State<SosPressHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // 3-second hold countdown
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onActivated();
        _controller.reset();
        setState(() => _isHolding = false);
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _cancelHold();
  }

  void _onTapCancel() {
    _cancelHold();
  }

  void _cancelHold() {
    if (_isHolding) {
      setState(() => _isHolding = false);
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Progress Track
          SizedBox(
            width: widget.size + 16,
            height: widget.size + 16,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 6,
                  backgroundColor: AppColors.alertEmergency.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.alertEmergency),
                );
              },
            ),
          ),

          // Main SOS Button Disc
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.size * (_isHolding ? 0.95 : 1.0),
            height: widget.size * (_isHolding ? 0.95 : 1.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.alertEmergency,
              boxShadow: [
                BoxShadow(
                  color: AppColors.alertEmergency.withValues(alpha: _isHolding ? 0.6 : 0.35),
                  blurRadius: _isHolding ? 24 : 14,
                  spreadRadius: _isHolding ? 4 : 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emergency_outlined,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  _isHolding ? 'HOLDING...' : 'HOLD 3 SEC',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
