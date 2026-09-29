import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/movies_bloc.dart';
import '../bloc/theme_bloc.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_editor.dart';
import '../widgets/search_field.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Любимые фильмы'),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(state.isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  context.read<ThemeBloc>().add(ThemeChanged(!state.isDark));
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SearchField(
              onChanged: (query) {
                context.read<MoviesBloc>().add(MoviesSearched(query));
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<MoviesBloc, MoviesState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.filteredMovies.isEmpty) {
                    return Center(
                      child: Text(
                        state.searchQuery.isEmpty
                            ? 'Фильмов пока нет.\nНажмите +, чтобы добавить!'
                            : 'Фильмы не найдены',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = state.filteredMovies[index];
                      return MovieCard(
                        movie: movie,
                        onTap: () => _showEditor(context, movie: movie),
                        onDelete: () => _confirmDelete(context, movie),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditor(BuildContext context, {Movie? movie}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => MovieEditor(
        movie: movie,
        onSave: (savedMovie) {
          if (movie == null) {
            context.read<MoviesBloc>().add(MovieAdded(savedMovie));
          } else {
            context.read<MoviesBloc>().add(MovieUpdated(savedMovie));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Movie movie) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Удаление фильма'),
        content: Text('Удалить "${movie.title}" из базы данных?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<MoviesBloc>().add(MovieDeleted(movie.id!));
              Navigator.pop(dialogCtx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}