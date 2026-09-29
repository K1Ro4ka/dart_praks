import '../../domain/quote.dart';

class QuoteModel extends Quote {
  const QuoteModel({
    required super.quote,
    required super.author,
    required super.category,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      quote: json['quote'] as String? ?? 'Текст отсутствует',
      author: json['author'] as String? ?? 'Неизвестный автор',
      category: json['category'] as String? ?? 'Общее',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quote': quote,
      'author': author,
      'category': category,
    };
  }
}