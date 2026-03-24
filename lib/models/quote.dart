import 'package:hive/hive.dart';

part 'quote.g.dart';

@HiveType(typeId: 0)
class Quote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String? source;

  @HiveField(5)
  final String? sourceSection;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    this.source,
    this.sourceSection,
  });

  /// Convenience getter — keeps any downstream code using `.book` working.
  String? get book => sourceSection;

  factory Quote.fromJson(Map<String, dynamic> json) {
    // id is an int in the JSON — cast it to String for Hive key use.
    final id = (json['id'] as num).toString();

    return Quote(
      id: id,
      text: json['text'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      source: json['source'] as String?,
      sourceSection: json['source_section'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        'category': category,
        'source': source,
        'source_section': sourceSection,
      };
}