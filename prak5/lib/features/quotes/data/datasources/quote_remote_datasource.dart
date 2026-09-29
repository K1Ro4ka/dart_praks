import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/quote_model.dart';

abstract class QuoteRemoteDataSource {
  Future<List<QuoteModel>> fetchQuotes(String? category);
}

class QuoteRemoteDataSourceImpl implements QuoteRemoteDataSource {
  final DioClient dioClient;

  QuoteRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<QuoteModel>> fetchQuotes(String? category) async {
    try {
      final response = await dioClient.dio.get(
        'quotes',
        queryParameters: category != null && category.isNotEmpty ? {'category': category} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => QuoteModel.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Не удалось получить данные с сервера',
        );
      }
    } on DioException {
      return [
        const QuoteModel(
          quote: 'Успех — это способность двигаться от неудачи к неудаче, не теряя энтузиазма.',
          author: 'Уинстон Черчилль',
          category: 'success',
        ),
        const QuoteModel(
          quote: 'Единственный способ делать великие дела — любить то, что вы делаете.',
          author: 'Стив Джобс',
          category: 'inspirational',
        ),
        const QuoteModel(
          quote: 'Знание само по себе — сила.',
          author: 'Фрэнсис Бэкон',
          category: 'knowledge',
        ),
      ];
    }
  }
}