import 'dart:io' show exit;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../profile.dart';
import '../services/sfx.dart';
import 'collection_screen.dart';
import 'local_duel_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'shop_screen.dart';
import 'story_screen.dart';
import 'tower_screen.dart';
import 'live_lobby_screen.dart';

const _night = Color(0xFF0B111B);
const _night2 = Color(0xFF172431);
const _green = Color(0xFF245442);
const _greenLight = Color(0xFF39765B);
const _gold = Color(0xFFC39A55);
const _goldLight = Color(0xFFE8CB8D);
const _ivory = Color(0xFFF4EBDD);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))..repeat(reverse: true);
  bool _light = false;
  bool _immersive = false;
  bool get _canExit => !kIsWeb && defaultTargetPlatform != TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    Profile.load().then((_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ambient.dispose(); _intro.dispose(); _pulse.dispose(); super.dispose(); }

  Future<void> _push(Widget page) async {
    Sfx.tap();
    await Navigator.of(context).push(PageRouteBuilder<void>(
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final c = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: c, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero).animate(c), child: child));
      },
      transitionDuration: const Duration(milliseconds: 420),
    ));
    if (mounted) setState(() {});
  }

  void _notice(String message) {
    Sfx.tap();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: _green));
  }

  Future<void> _toggleImmersive() async {
    Sfx.tap(); _immersive = !_immersive;
    await SystemChrome.setEnabledSystemUIMode(_immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bg = _light ? const Color(0xFFE9DFC9) : _night;
    final fg = _light ? const Color(0xFF26382F) : _ivory;
    final muted = _light ? const Color(0xFF71634D) : const Color(0xFFB6B4B0);
    final (level, current, needed) = Profile.progress();
    final dark = !_light;
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        Positioned.fill(child: AnimatedBuilder(animation: _ambient, builder: (_, __) => CustomPaint(painter: _MenuAtmospherePainter(t: _ambient.value, light: _light)))),
        SafeArea(child: LayoutBuilder(builder: (context, c) {
          return Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(children: [
                // ---- top bar: level, name, xp, gold, settings
                _enter(0, Row(children: [
                  Container(width: 50, height: 50, alignment: Alignment.center,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4C8BE0), Color(0xFF2456A6)]), border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 3))]),
                    child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black87, offset: Offset(0, 2))]))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Hedy', style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Stack(alignment: Alignment.center, children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: needed == 0 ? 0 : current / needed, minHeight: 15, backgroundColor: Colors.black38, valueColor: const AlwaysStoppedAnimation(Color(0xFFB65CF0)))),
                      Text('$current / $needed', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ]),
                  ])),
                  const SizedBox(width: 10),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold, width: 1.5)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54A), size: 20), const SizedBox(width: 4), Text('${Profile.gold}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))])),
                  const SizedBox(width: 6),
                  _HeaderAction(icon: Icons.wb_sunny_outlined, label: _light ? 'Mode clair' : 'Mode sombre', onTap: () { Sfx.tap(); setState(() => _light = !_light); }),
                  const SizedBox(width: 6),
                  _HeaderAction(icon: Icons.settings_rounded, label: 'Paramètres', onTap: () => _push(const SettingsScreen())),
                ])),
                // ---- arena: title + crest (takes the free space)
                Expanded(child: _enter(1, FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('THE LAST MESSAGE', style: TextStyle(color: dark ? _goldLight : _green, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3, shadows: const [Shadow(color: Colors.black87, offset: Offset(0, 3), blurRadius: 2)])),
                  const SizedBox(height: 4),
                  Text('Qur’an 18:1', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.4)),
                  _MainCrest(light: _light, pulse: _pulse, onTap: () => _push(const SetupScreen())),
                ])))),
                // ---- big battle button
                _enter(2, _ChunkyButton(label: 'COMBAT', icon: Icons.sports_martial_arts_rounded, top: const Color(0xFFFFD54A), bottom: const Color(0xFFE59A12), textColor: const Color(0xFF3A2A00), height: 74, fontSize: 30, pulse: _pulse, onTap: () => _push(const SetupScreen()))),
                const SizedBox(height: 12),
                // ---- two big mode buttons
                _enter(3, Row(children: [
                  Expanded(child: _ChunkyButton(label: 'HISTOIRE', icon: Icons.auto_stories_rounded, top: const Color(0xFF58C27A), bottom: const Color(0xFF237A45), height: 62, fontSize: 14, onTap: () => _push(const StoryScreen()))),
                  const SizedBox(width: 8),
                  Expanded(child: _ChunkyButton(label: 'LA TOUR', icon: Icons.stairs_rounded, top: const Color(0xFFE5675A), bottom: const Color(0xFF9A2B22), height: 62, fontSize: 14, onTap: () => _push(const TowerScreen()))),
                  const SizedBox(width: 8),
                  Expanded(child: _ChunkyButton(label: 'SARIYYA', icon: Icons.bolt_rounded, top: const Color(0xFF8E6BE0), bottom: const Color(0xFF4A2FA0), height: 62, fontSize: 14, onTap: () => _push(const LiveLobbyScreen()))),
                ])),
                const SizedBox(height: 12),
                // ---- bottom navigation bar
                _enter(4, Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E4A66), Color(0xFF16263A)]), border: Border.all(color: _gold.withOpacity(.6), width: 1.5), boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 4))]),
                  child: Row(children: [
                    Expanded(child: _NavItem(icon: Icons.account_balance_rounded, label: 'Boutique', onTap: () => _push(const ShopScreen()))),
                    Expanded(child: _NavItem(icon: Icons.collections_bookmark_rounded, label: 'Collection', onTap: () => _push(const CollectionScreen()))),
                    Expanded(child: _NavItem(icon: Icons.cell_tower_rounded, label: 'Duel local', onTap: () => _push(const LocalDuelLobbyScreen()))),
                    Expanded(child: _NavItem(icon: Icons.menu_book_rounded, label: 'Règles', onTap: () => _push(const RulesScreen()))),
                    Expanded(child: _NavItem(icon: _immersive ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, label: 'Écran', onTap: _toggleImmersive)),
                  ]),
                )),
              ]),
            ),
          ));
        })),
      ]),
    );
  }

  Widget _enter(int index, Widget child) => AnimatedBuilder(animation: _intro, builder: (_, __) {
    final start = index * .105;
    final v = ((_intro.value - start) / (1 - start)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(v);
    return Opacity(opacity: eased, child: Transform.translate(offset: Offset(0, 22 * (1 - eased)), child: child));
  });
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Tooltip(message: label, child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withOpacity(.09), border: Border.all(color: _gold.withOpacity(.55))), child: Icon(icon, color: _goldLight, size: 21)))));
}

class _MainCrest extends StatelessWidget {
  const _MainCrest({required this.light, required this.pulse, required this.onTap});
  final bool light; final Animation<double> pulse; final VoidCallback onTap;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: pulse, builder: (_, __) {
    final p = pulse.value;
    return SizedBox(height: 218, child: Center(child: GestureDetector(onTap: onTap, child: SizedBox(width: 218, height: 218, child: Stack(alignment: Alignment.center, children: [
      Transform.rotate(angle: math.pi / 4, child: Container(width: 164 + p * 5, height: 164 + p * 5, decoration: BoxDecoration(border: Border.all(color: _gold.withOpacity(.62), width: 1.2), boxShadow: [BoxShadow(color: _gold.withOpacity(.12 + p * .12), blurRadius: 24 + p * 12, spreadRadius: 2)]))),
      Transform.rotate(angle: -math.pi / 4, child: Container(width: 142, height: 142, decoration: BoxDecoration(border: Border.all(color: _goldLight.withOpacity(.65), width: 1), shape: BoxShape.circle))),
      Container(width: 126, height: 126, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [_greenLight, _green, _night2]), border: Border.all(color: _goldLight.withOpacity(.9), width: 2), boxShadow: [BoxShadow(color: _gold.withOpacity(.2 + p * .18), blurRadius: 28 + p * 15)]), child: const Icon(Icons.sports_martial_arts_rounded, color: _ivory, size: 55)),
      Positioned(bottom: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7), decoration: BoxDecoration(color: light ? const Color(0xFFE9DFC9) : _night, border: Border.all(color: _gold, width: 1), borderRadius: BorderRadius.circular(3)), child: Text('JOUER', style: TextStyle(color: light ? _green : _goldLight, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3)))),
    ])))));
  });
}

class _MenuPlaque extends StatefulWidget {
  const _MenuPlaque({required this.icon, required this.title, required this.subtitle, required this.light, required this.delay, required this.onTap});
  final IconData icon; final String title, subtitle; final bool light; final int delay; final VoidCallback onTap;
  @override State<_MenuPlaque> createState() => _MenuPlaqueState();
}
class _MenuPlaqueState extends State<_MenuPlaque> with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(vsync: this, duration: Duration(milliseconds: 2400 + widget.delay * 180))..repeat();
  bool _pressed = false;
  @override void dispose() { _shine.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final titleColor = widget.light ? const Color(0xFF26382F) : _ivory;
    return AnimatedScale(scale: _pressed ? .965 : 1, duration: const Duration(milliseconds: 120), child: GestureDetector(onTapDown: (_) => setState(() => _pressed = true), onTapCancel: () => setState(() => _pressed = false), onTapUp: (_) => setState(() => _pressed = false), onTap: widget.onTap, child: AnimatedBuilder(animation: _shine, builder: (_, __) {
      final shimmer = (_shine.value * 2 - 1);
      return ClipPath(clipper: _PlaqueClipper(), child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.light ? [const Color(0xFFFFF8E9), const Color(0xFFD8C9A9)] : [const Color(0xFF263B43), const Color(0xFF111B29), const Color(0xFF1C2B35)]), border: Border.all(color: _gold.withOpacity(.75), width: 1.2), boxShadow: [BoxShadow(color: _gold.withOpacity(.10 + .08 * (1 + shimmer)), blurRadius: 13, spreadRadius: 1)],
        ), child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _PlaqueOrnamentPainter(color: _gold.withOpacity(.35)))),
          Positioned(right: -30 + shimmer * 12, top: -28, child: Transform.rotate(angle: .45, child: Container(width: 90, height: 150, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _gold.withOpacity(.09), Colors.transparent]))))),
          Padding(padding: const EdgeInsets.fromLTRB(18, 13, 16, 13), child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_gold.withOpacity(.24), _green.withOpacity(.2)]), border: Border.all(color: _gold.withOpacity(.65))), child: Icon(widget.icon, color: _goldLight, size: 25)),
            const SizedBox(width: 12), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.05)), const SizedBox(height: 4), Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor.withOpacity(.65), fontSize: 10))])),
            Icon(Icons.chevron_right_rounded, color: _gold.withOpacity(.85), size: 22),
          ])),
        ]),
      ));
    })));
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: _gold), const SizedBox(width: 7), Text(label, style: TextStyle(color: color.withOpacity(.7), fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w700))])));
}

class _PlaqueClipper extends CustomClipper<Path> {
  @override Path getClip(Size s) { final p = Path()..moveTo(14, 0)..lineTo(s.width - 14, 0)..lineTo(s.width, 14)..lineTo(s.width, s.height - 14)..lineTo(s.width - 14, s.height)..lineTo(14, s.height)..lineTo(0, s.height - 14)..lineTo(0, 14)..close(); return p; }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PlaqueOrnamentPainter extends CustomPainter {
  _PlaqueOrnamentPainter({required this.color}); final Color color;
  @override void paint(Canvas canvas, Size s) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = .7..color = color; canvas.drawRect(Rect.fromLTWH(7, 7, s.width - 14, s.height - 14), p); for (final x in [10.0, s.width - 10]) { final path = Path()..moveTo(x, 19)..lineTo(x, 8)..lineTo(x + (x < s.width / 2 ? 11 : -11), 8); canvas.drawPath(path, p); } }
  @override bool shouldRepaint(covariant _PlaqueOrnamentPainter oldDelegate) => oldDelegate.color != color;
}

class _MenuAtmospherePainter extends CustomPainter {
  _MenuAtmospherePainter({required this.t, required this.light}); final double t; final bool light;
  @override void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    final base = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: light ? [const Color(0xFFF2E9D7), const Color(0xFFD8C9AC), const Color(0xFFEDE3D0)] : [_night, const Color(0xFF172633), const Color(0xFF080D16)]).createShader(rect);
    canvas.drawRect(rect, base);
    final glow = Paint()..shader = RadialGradient(colors: [(_gold).withOpacity(light ? .10 : .10), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(s.width * (.5 + .07 * math.sin(t * math.pi * 2)), s.height * .55), radius: s.width * .72));
    canvas.drawRect(rect, glow);
    final lattice = Paint()..style = PaintingStyle.stroke..strokeWidth = .65..color = (light ? _green : _goldLight).withOpacity(light ? .075 : .09);
    const step = 48.0;
    for (double y = -step; y < s.height + step; y += step) { for (double x = -step; x < s.width + step; x += step) { canvas.save(); canvas.translate(x + ((y / step).floor().isOdd ? step / 2 : 0), y); final r = Rect.fromCenter(center: Offset.zero, width: 31, height: 31); canvas.drawRect(r, lattice); canvas.rotate(math.pi / 4); canvas.drawRect(r, lattice); canvas.restore(); } }
    // Distant fortress silhouette, drawn in code (not a background image).
    final ground = Paint()..color = (light ? _green : const Color(0xFF050A10)).withOpacity(light ? .14 : .55);
    final y0 = s.height * .47;
    final fortress = Path()..moveTo(0, y0 + 48)..lineTo(s.width * .12, y0 + 48)..lineTo(s.width * .12, y0 + 12)..lineTo(s.width * .17, y0 + 12)..lineTo(s.width * .17, y0 - 5)..lineTo(s.width * .21, y0 - 5)..lineTo(s.width * .21, y0 + 25)..lineTo(s.width * .31, y0 + 25)..lineTo(s.width * .31, y0 - 24)..lineTo(s.width * .36, y0 - 24)..lineTo(s.width * .36, y0 + 4)..lineTo(s.width * .43, y0 + 4)..lineTo(s.width * .43, y0 - 42)..lineTo(s.width * .48, y0 - 42)..lineTo(s.width * .48, y0 - 10)..lineTo(s.width * .53, y0 - 10)..lineTo(s.width * .53, y0 + 12)..lineTo(s.width * .62, y0 + 12)..lineTo(s.width * .62, y0 - 22)..lineTo(s.width * .67, y0 - 22)..lineTo(s.width * .67, y0 + 20)..lineTo(s.width * .78, y0 + 20)..lineTo(s.width * .78, y0 - 4)..lineTo(s.width * .83, y0 - 4)..lineTo(s.width * .83, y0 + 35)..lineTo(s.width, y0 + 35)..lineTo(s.width, s.height)..lineTo(0, s.height)..close();
    canvas.drawPath(fortress, ground);
    // Slow drifting embers/stars.
    final particle = Paint()..color = _goldLight.withOpacity(light ? .18 : .32);
    for (var i = 0; i < 24; i++) { final x = ((i * 71.0 + t * s.width * (i.isEven ? .10 : -.07)) % s.width); final y = (i * 113.0 + (t * 170 * (i % 3 + 1))) % s.height; canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 1.5 : .8, particle); }
  }
  @override bool shouldRepaint(covariant _MenuAtmospherePainter oldDelegate) => oldDelegate.t != t || oldDelegate.light != light;
}


/// Chunky 3D-style button (Clash Royale look): bright gradient, dark lip, white outline.
class _ChunkyButton extends StatefulWidget {
  const _ChunkyButton({required this.label, required this.icon, required this.top, required this.bottom, required this.height, required this.fontSize, required this.onTap, this.textColor = Colors.white, this.pulse});
  final String label; final IconData icon; final Color top, bottom, textColor; final double height, fontSize; final VoidCallback onTap; final Animation<double>? pulse;
  @override State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _down = false;
  @override Widget build(BuildContext context) {
    final lip = Color.lerp(widget.bottom, Colors.black, .45)!;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      height: widget.height,
      margin: EdgeInsets.only(top: _down ? 5 : 0, bottom: _down ? 0 : 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [widget.top, widget.bottom]),
        border: Border.all(color: Colors.white.withOpacity(.9), width: 2.2),
        boxShadow: [BoxShadow(color: lip, offset: Offset(0, _down ? 0 : 5)), const BoxShadow(color: Colors.black45, offset: Offset(0, 8), blurRadius: 8)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 6),
        const SizedBox(width: 10),
        Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.textColor, fontSize: widget.fontSize, fontWeight: FontWeight.w900, letterSpacing: 1.5, shadows: widget.textColor == Colors.white ? const [Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 1)] : null))),
      ]),
    );
    Widget child = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () { Sfx.tap(); widget.onTap(); },
      child: body,
    );
    final pulse = widget.pulse;
    if (pulse != null) {
      child = AnimatedBuilder(animation: pulse, builder: (_, c) => Transform.scale(scale: 1 + pulse.value * .018, child: c), child: child);
    }
    return child;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () { Sfx.tap(); onTap(); },
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _goldLight, size: 26),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ivory, fontSize: 10, fontWeight: FontWeight.w800)),
    ])),
  );
}
