import 'package:flutter/material.dart';

import '../domain/book.dart';

class BookCover extends StatelessWidget {
  const BookCover({required this.book, this.width = 76, super.key});

  final Book book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = Color(book.coverColor);
    return Container(
      width: width,
      height: width * 1.42,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_stories, color: Colors.white, size: 20),
          const Spacer(),
          Text(
            book.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}
