import 'package:flutter/material.dart';
import '../models/movie.dart';

class MovieEditor extends StatefulWidget {
  final Movie? movie;
  final Function(Movie) onSave;

  const MovieEditor({
    super.key,
    this.movie,
    required this.onSave,
  });

  @override
  State<MovieEditor> createState() => _MovieEditorState();
}

class _MovieEditorState extends State<MovieEditor> {
  late TextEditingController _titleController;
  late TextEditingController _yearController;
  late TextEditingController _genreController;
  late TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.movie?.title ?? '');
    _yearController = TextEditingController(text: widget.movie?.year.toString() ?? '');
    _genreController = TextEditingController(text: widget.movie?.genre ?? '');
    _imageController = TextEditingController(text: widget.movie?.imageUrl ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.movie == null ? 'Новый фильм' : 'Редактировать фильм'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название фильма'),
            ),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Год выпуска'),
            ),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Жанр'),
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Ссылка на постер (URL)',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveMovie,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _saveMovie() {
    final title = _titleController.text.trim();
    final year = int.tryParse(_yearController.text.trim()) ?? 2024;
    final genre = _genreController.text.trim();
    final imageUrl = _imageController.text.trim();

    if (title.isNotEmpty) {
      final movie = Movie(
        id: widget.movie?.id,
        title: title,
        year: year,
        genre: genre.isEmpty ? 'Не указан' : genre,
        imageUrl: imageUrl,
      );
      widget.onSave(movie);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}