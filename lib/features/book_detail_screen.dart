import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../l10n/strings.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isCorpus = book.availability == 'hadith_import_required' || book.availability == 'quran_import_required';
    final isDossier = book.availability == 'study_dossier';
    final hasPdf = book.pdfUrl != null && book.pdfUrl!.isNotEmpty;
    final canRead = isCorpus || isDossier || book.availability == 'integrated' || hasPdf;
    final readerLabel = hasPdf
        ? (Strings.lang == 'ar' ? 'فتح قارئ PDF' : (Strings.lang == 'en' ? 'Read PDF in app' : 'Lire le PDF dans l’application'))
        : (isDossier ? (Strings.lang == 'ar' ? 'فتح ملف القراءة' : (Strings.lang == 'en' ? 'Open study dossier' : 'Ouvrir le dossier de lecture')) : tr('book_open_reader'));
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        children: [
          Center(child: Container(
            width: 104, height: 132,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.menu_book_rounded, size: 54, color: cs.onPrimaryContainer),
          )),
          const SizedBox(height: 22),
          Text(book.title, style: tt.headlineSmall, textAlign: TextAlign.center),
          if (book.titleAr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(textDirection: TextDirection.rtl, child: Text(book.titleAr,
              style: tt.titleLarge?.copyWith(color: cs.primary), textAlign: TextAlign.center)),
          ],
          const SizedBox(height: 8),
          Text(book.author, textAlign: TextAlign.center, style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          if (book.edition.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(book.edition, textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 28),
          if (book.description.isNotEmpty)
            Text(book.description, style: tt.bodyLarge?.copyWith(height: 1.55), textAlign: TextAlign.center),
          if (book.rightsNote != null && book.rightsNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(book.rightsNote!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 28),
          if (canRead) FilledButton.icon(
            onPressed: () => context.push(isCorpus
              ? (book.availability == 'quran_import_required' ? '/quran' : '/hadith/${book.id}')
              : (hasPdf ? '/pdf/${book.id}' : '/book/${book.id}/read')),
            icon: const Icon(Icons.chrome_reader_mode_outlined),
            label: Text(readerLabel),
          ),
          if (hasPdf) ...[
            const SizedBox(height: 12),
            Text(Strings.lang == 'ar' ? 'يُفتح ملف PDF داخل قارئ التطبيق، لكنه لا يزال مستضافًا في المكتبة الرقمية ويتطلب اتصالًا بالإنترنت؛ ولم يُدمج بعد للعمل دون اتصال.' : (Strings.lang == 'en' ? 'The PDF opens in the in-app reader. This edition is still hosted by the digital library and requires an internet connection; offline bundling is not yet available.' : 'Le PDF s’ouvre dans le lecteur intégré à l’application, mais cette édition reste hébergée par la bibliothèque numérique et nécessite une connexion. Son intégration hors ligne reste à faire.'), textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          if (isDossier) ...[
            const SizedBox(height: 16),
            Text(Strings.lang == 'ar' ? 'ملاحظات تحريرية وليست نصاً كاملاً للكتاب. لا توجد صفحات أو اقتباسات حرفية غير محققة.' : (Strings.lang == 'en' ? 'Editorial study notes, not the complete book text. No unverified page numbers or quotations are presented.' : 'Notes de lecture éditoriales, et non le texte intégral du livre. Aucun numéro de page ni citation non vérifiés ne sont présentés.'), textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          if (!canRead) ...[
            const SizedBox(height: 10),
            Text(tr('book_not_integrated_note'), textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
