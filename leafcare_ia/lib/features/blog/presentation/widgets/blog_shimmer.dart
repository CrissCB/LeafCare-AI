import 'package:flutter/material.dart';

class BlogShimmer extends StatefulWidget {
  const BlogShimmer({super.key});

  @override
  State<BlogShimmer> createState() => _BlogShimmerState();
}

class _BlogShimmerState extends State<BlogShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _box(height: 200, radius: 24),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _box(height: 90, radius: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _box({required double height, required double radius}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_anim.value, 0),
          end: Alignment(_anim.value + 1.5, 0),
          colors: const [
            Color(0xFFE8F5E9),
            Color(0xFFD1FAE5),
            Color(0xFFE8F5E9),
          ],
        ),
      ),
    );
  }
}
