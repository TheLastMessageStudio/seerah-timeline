import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../data/models.dart';

class PdfBookScreen extends StatelessWidget {
  final Book book;
  const PdfBookScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final url = book.pdfUrl;
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: url == null || url.isEmpty
          ? const Center(child: Text('Aucun PDF disponible pour cette édition.'))
          : PdfViewer.uri(
              Uri.parse(url),
              useProgressiveLoading: true,
              params: const PdfViewerParams(enableTextSelection: true),
            ),
    );
  }
}
