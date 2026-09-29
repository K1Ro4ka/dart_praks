import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repositories/theme_repository.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object> get props => [];
}

class ThemeLoaded extends ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final bool isDark;
  const ThemeChanged(this.isDark);
  @override
  List<Object> get props => [isDark];
}

class ThemeState extends Equatable {
  final bool isDark;
  const ThemeState({required this.isDark});
  @override
  List<Object> get props => [isDark];
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository _themeRepository;

  ThemeBloc(this._themeRepository) : super(const ThemeState(isDark: false)) {
    on<ThemeLoaded>((event, emit) async {
      final isDark = await _themeRepository.getTheme() ?? false;
      emit(ThemeState(isDark: isDark));
    });

    on<ThemeChanged>((event, emit) async {
      await _themeRepository.saveTheme(event.isDark);
      emit(ThemeState(isDark: event.isDark));
    });
  }
}