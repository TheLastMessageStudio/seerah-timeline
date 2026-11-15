import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../core/arabic_search.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';

class BookLibraryScreen extends StatefulWidget {
  final AppState state;
  const BookLibraryScreen({super.key, required this.state});

  @override
  State<BookLibraryScreen> createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> {
  String query = '';

  bool _matches(Book book) {
    final q = normalizeSearchText(query.trim());
    if (q.isEmpty) return true;
    final haystack = normalizeSearchText(
      '${book.title} ${book.titleAr} ${book.author} ${book.id}',
    );
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.state.repo.books.where(_matches).toList();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('books_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('books_search'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: books.isEmpty
                ? Center(child: Text(tr('no_results')))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.menu_book_outlined,
                                color: cs.onPrimaryContainer),
                          ),
                          title: Text(book.title,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(book.author),
                                if (book.pdfUrl != null) ...[
                                  const SizedBox(height: 3),
                                  Text(Strings.lang == 'en' ? 'PDF reader in app' : (Strings.lang == 'ar' ? 'قارئ PDF داخل التطبيق' : 'Lecteur PDF intégré'), style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                ] else if (book.availability != 'hadith_import_required' && book.availability != 'quran_import_required') ...[
                                  const SizedBox(height: 3),
                                  Text(Strings.lang == 'en' ? 'In-app reading not yet integrated' : (Strings.lang == 'ar' ? 'القراءة داخل التطبيق غير مدمجة بعد' : 'Lecture intégrée non disponible pour le moment'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                ],
                                if (book.availability == 'metadata_only') ...[
                                  const SizedBox(height: 3),
                                  Text(tr('book_not_integrated'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                ],
                                if (book.availability == 'study_dossier') ...[
                                  const SizedBox(height: 3),
                                  Text(tr('book_study_dossier'), style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                                if (book.titleAr.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Directionality(textDirection: TextDirection.rtl,
                                    child: Text(book.titleAr, style: TextStyle(color: cs.primary, fontSize: 12))),
                                ],
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/book/${book.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
