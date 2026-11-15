import 'package:flutter/material.dart';

import '../strings.dart';
import 'theme.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  static const int pages = 8;
  static const icons = [
    Icons.map, Icons.flag, Icons.directions_walk, Icons.group,
    Icons.gps_fixed, Icons.visibility_off, Icons.style, Icons.emoji_events,
  ];
  final PageController pc = PageController();
  int page = 0;

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('menu_tutorial'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pc,
                itemCount: pages,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i], size: 72, color: Pal.bronze),
                      const SizedBox(height: 16),
                      Text(tr('tut_${i + 1}_t'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Pal.green)),
                      const SizedBox(height: 12),
                      Text(tr('tut_${i + 1}_b'),
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page ? Pal.green : Pal.bronze.withAlpha(90),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: page == 0
                          ? null
                          : () => pc.previousPage(
                              duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                      child: Text(tr('tut_prev')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (page == pages - 1) {
                          Navigator.of(context).pop();
                        } else {
                          pc.nextPage(
                              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                        }
                      },
                      child: Text(page == pages - 1 ? tr('tut_done') : tr('tut_next')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
