import 'package:get_it/get_it.dart';
import '../../features/quotes/data/datasources/quote_remote_datasource.dart';
import '../../features/quotes/data/repositories/quote_repository_impl.dart';
import '../../features/quotes/domain/repositories/quote_repository.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance; 

Future<void> initDependencies() async {
  sl.registerLazySingleton<DioClient>(() => DioClient());

  sl.registerLazySingleton<QuoteRemoteDataSource>(
    () => QuoteRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<QuoteRepository>(
    () => QuoteRepositoryImpl(remoteDataSource: sl()),
  );
}