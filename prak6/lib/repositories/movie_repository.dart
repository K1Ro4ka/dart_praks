import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class MovieRepository {
  static Database? _database;
  static const String _webKey = 'saved_movies_web_storage';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('movies_bloc_cubit.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE movies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            year INTEGER NOT NULL,
            genre TEXT NOT NULL,
            imageUrl TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Movie>> getMovies() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_webKey);
      if (data == null) {
        return [
          Movie(
            id: 1,
            title: 'Интерстеллар',
            year: 2014,
            genre: 'Фантастика',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/ru/c/c3/Interstellar_2014.jpg?utm_source=ru.wikipedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled',
          ),
          Movie(
            id: 2,
            title: 'Начало',
            year: 2010,
            genre: 'Боевик, Фантастика',
            imageUrl: 'https://avatars.mds.yandex.net/get-kinopoisk-image/1629390/8ab9a119-dd74-44f0-baec-0629797483d7/600x900',
          ),
        ];
      }
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Movie.fromMap(Map<String, dynamic>.from(e))).toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('movies', orderBy: 'id DESC');
      return maps.map((e) => Movie.fromMap(e)).toList();
    }
  }

  Future<Movie> insertMovie(Movie movie) async {
    if (kIsWeb) {
      final movies = await getMovies();
      final newMovie = movie.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      movies.insert(0, newMovie);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webKey, jsonEncode(movies.map((m) => m.toMap()).toList()));
      return newMovie;
    } else {
      final db = await database;
      final id = await db.insert('movies', movie.toMap());
      return movie.copyWith(id: id);
    }
  }

  Future<int> updateMovie(Movie movie) async {
    if (kIsWeb) {
      final movies = await getMovies();
      final index = movies.indexWhere((m) => m.id == movie.id);
      if (index != -1) {
        movies[index] = movie;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_webKey, jsonEncode(movies.map((m) => m.toMap()).toList()));
      }
      return 1;
    } else {
      final db = await database;
      return await db.update(
        'movies',
        movie.toMap(),
        where: 'id = ?',
        whereArgs: [movie.id],
      );
    }
  }

  Future<int> deleteMovie(int id) async {
    if (kIsWeb) {
      final movies = await getMovies();
      movies.removeWhere((m) => m.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webKey, jsonEncode(movies.map((m) => m.toMap()).toList()));
      return 1;
    } else {
      final db = await database;
      return await db.delete(
        'movies',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}