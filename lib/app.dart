import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/movies_bloc.dart';
import 'bloc/theme_bloc.dart';
import 'repositories/movie_repository.dart';
import 'repositories/theme_repository.dart';
import 'screens/movies_screen.dart';

class MoviesApp extends StatelessWidget {
  const MoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeBloc(ThemeRepository())..add(ThemeLoaded()),
        ),
        BlocProvider(
          create: (context) => MoviesBloc(MovieRepository())..add(MoviesLoaded()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Любимые фильмы',
            debugShowCheckedModeBanner: false,
            themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 183, 58, 156),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 183, 58, 156),
                brightness: Brightness.dark,
              ),
            ),
            home: const MoviesScreen(),
          );
        },
      ),
    );
  }
}