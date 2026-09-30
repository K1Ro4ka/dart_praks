import 'package:get_it/get_it.dart';
import '../../features/auth/data/auth_remote_datasource.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/notes/data/datasources/notes_firestore_datasource.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Модуль авторизации (Auth)
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // 2. Модуль облачной базы данных Firestore (Notes)
  sl.registerLazySingleton<NotesRepository>(() => NotesRepositoryImpl());
}