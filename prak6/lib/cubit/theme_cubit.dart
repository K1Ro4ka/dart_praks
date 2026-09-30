import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/theme_repository.dart';

class ThemeCubit extends Cubit<bool> {
  final ThemeRepository _themeRepository;

  ThemeCubit(this._themeRepository) : super(false);

  Future<void> loadTheme() async {
    final isDark = await _themeRepository.getTheme() ?? false;
    emit(isDark);
  }

  Future<void> toggleTheme(bool isDark) async {
    await _themeRepository.saveTheme(isDark);
    emit(isDark);
  }
}