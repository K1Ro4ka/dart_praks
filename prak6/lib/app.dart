import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/movies_bloc.dart';
import 'cubit/theme_cubit.dart';
import 'repositories/movie_repository.dart';
import 'repositories/theme_repository.dart';
import 'screens/movies_screen.dart';

class MoviesApp extends StatelessWidget {
  const MoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(ThemeRepository())..loadTheme(),
        ),
        // 2. Подключение MoviesBloc (BLoC)
        BlocProvider<MoviesBloc>(
          create: (context) => MoviesBloc(MovieRepository())..add(MoviesLoaded()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDark) {
          return MaterialApp(
            title: 'Любимые фильмы (Bloc & Cubit)',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: Colors.teal,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.teal,
            ),
            home: const MoviesScreen(),
          );
        },
      ),
    );
  }
}