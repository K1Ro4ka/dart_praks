import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/movies_bloc.dart';
import '../cubit/theme_cubit.dart';
import '../models/movie.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильмы (Bloc & Cubit)'),
        actions: [
          BlocBuilder<ThemeCubit, bool>(
            builder: (context, isDark) {
              return Row(
                children: [
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  Switch(
                    value: isDark,
                    onChanged: (val) {
                      context.read<ThemeCubit>().toggleTheme(val);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              onChanged: (query) {
                context.read<MoviesBloc>().add(MoviesSearched(query));
              },
              decoration: InputDecoration(
                hintText: 'Поиск по названию или жанру...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
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
                            ? 'Фильмов нет. Нажмите +, чтобы добавить.'
                            : 'Фильмы не найдены.',
                      ),  
                    );
                  }

                  return ListView.builder(
                    itemCount: state.filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = state.filteredMovies[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: movie.imageUrl.isNotEmpty
                                    ? Image.network(
                                        movie.imageUrl,
                                        width: 65,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 65,
                                          height: 90,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : Container(
                                        width: 65,
                                        height: 90,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.movie),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Год: ${movie.year}'),
                                    Text('Жанр: ${movie.genre}'),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _openDialog(context, movie: movie),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  context.read<MoviesBloc>().add(MovieDeleted(movie.id!));
                                },
                              ),
                            ],
                          ),
                        ),
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
        onPressed: () => _openDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openDialog(BuildContext context, {Movie? movie}) {
    final titleCtrl = TextEditingController(text: movie?.title ?? '');
    final yearCtrl = TextEditingController(text: movie?.year.toString() ?? '');
    final genreCtrl = TextEditingController(text: movie?.genre ?? '');
    final imageCtrl = TextEditingController(text: movie?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(movie == null ? 'Добавить фильм' : 'Редактировать фильм'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название')),
              TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Год')),
              TextField(controller: genreCtrl, decoration: const InputDecoration(labelText: 'Жанр')),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Ссылка на постер')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final year = int.tryParse(yearCtrl.text.trim()) ?? 2024;
              final genre = genreCtrl.text.trim();
              final imageUrl = imageCtrl.text.trim();

              if (title.isNotEmpty) {
                if (movie == null) {
                  context.read<MoviesBloc>().add(
                        MovieAdded(Movie(
                          title: title,
                          year: year,
                          genre: genre.isEmpty ? 'Не указан' : genre,
                          imageUrl: imageUrl,
                        )),
                      );
                } else {
                  context.read<MoviesBloc>().add(
                        MovieUpdated(Movie(
                          id: movie.id,
                          title: title,
                          year: year,
                          genre: genre.isEmpty ? 'Не указан' : genre,
                          imageUrl: imageUrl,
                        )),
                      );
                }
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}