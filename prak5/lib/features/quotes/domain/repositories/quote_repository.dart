import '../quote.dart';

abstract class QuoteRepository {
  Future<List<Quote>> getQuotes({String? category});
}