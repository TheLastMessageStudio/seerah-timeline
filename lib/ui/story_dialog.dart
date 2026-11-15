import 'package:flutter/material.dart';

import '../models/story.dart';
import '../models/units.dart';
import '../strings.dart';
import 'hero_card.dart';
import 'theme.dart';

/// Shows story lines one after the other (tap Next). Returns when finished
/// or skipped.
Future<void> showStoryDialog(BuildContext context, List<StoryLine> lines, {String? header, String? footer}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _StoryDialog(lines: lines, header: header, footer: footer),
  );
}

class _StoryDialog extends StatefulWidget {
  const _StoryDialog({required this.lines, this.header, this.footer});
  final List<StoryLine> lines;
  final String? header;
  final String? footer;

  @override
  State<_StoryDialog> createState() => _StoryDialogState();
}

class _StoryDialogState extends State<_StoryDialog> {
  int i = 0;

  Widget _portrait(StoryLine l) {
    final t = unitById[l.speaker];
    if (!l.hint && t != null) return heroPortrait(t, 60);
    final icon = l.hint
        ? Icons.lightbulb
        : (l.speaker.isEmpty ? Icons.auto_stories : Icons.record_voice_over);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Pal.gold.withAlpha(40),
        border: Border.all(color: l.hint ? Pal.turquoise : Pal.gold, width: 2),
      ),
      child: Icon(icon, color: l.hint ? Pal.turquoise : Pal.bronze, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lines[i];
    final last = i == widget.lines.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Pal.parchment,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: l.hint ? Pal.turquoise : Pal.bronze, width: 3),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.header != null && i == 0) ...[
                  Text(widget.header!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Pal.green)),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    _portrait(l),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l.speakerName,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: l.hint ? Pal.turquoise : Pal.indigo)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l.text,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontStyle: l.speaker.isEmpty && !l.hint ? FontStyle.italic : FontStyle.normal)),
                if (widget.footer != null && last) ...[
                  const SizedBox(height: 10),
                  Text(widget.footer!, style: const TextStyle(fontSize: 11, color: Pal.bronze)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('${i + 1}/${widget.lines.length}', style: const TextStyle(color: Pal.bronze)),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(tr('story_skip')),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        if (last) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => i++);
                        }
                      },
                      child: Text(last ? tr('story_close') : tr('story_next')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
