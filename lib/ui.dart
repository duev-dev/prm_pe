import 'package:flutter/material.dart';

const brandGradient = LinearGradient(
  colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B2FF7));
  final r16 = BorderRadius.circular(16);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F4FB),
    appBarTheme: const AppBarTheme(centerTitle: true, scrolledUnderElevation: 0, backgroundColor: Colors.transparent),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: r16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: r16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
  );
}

/// Fades + slides its child up once when first built. [index] staggers list items.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 350 + 70 * index.clamp(0, 8)),
    curve: Curves.easeOutCubic,
    builder: (_, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 28 * (1 - t)), child: child),
    ),
    child: child,
  );
}

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool busy;
  const GradientButton({super.key, required this.onPressed, required this.label, this.icon, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final r = BorderRadius.circular(16);
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: brandGradient,
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: r,
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: busy
                      ? const [
                          SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        ]
                      : [
                          if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                          Text(
                            label,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient page with decorative bubbles and a white card holding the form (login / register).
class AuthShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  const AuthShell({super.key, required this.icon, required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    Widget bubble(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: brandGradient),
        child: Stack(
          children: [
            Positioned(top: -60, right: -40, child: bubble(200, 0.12)),
            Positioned(top: 140, left: -70, child: bubble(160, 0.08)),
            Positioned(bottom: -50, right: 30, child: bubble(140, 0.10)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (_, s, child) => Transform.scale(scale: s, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                          child: Icon(icon, size: 56, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 2,
                        child: Card(
                          elevation: 12,
                          shadowColor: Colors.black26,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
