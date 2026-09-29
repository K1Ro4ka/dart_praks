import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/movie.dart';
import '../repositories/movie_repository.dart';

abstract class MoviesEvent extends Equatable {
  const MoviesEvent();
  @override
  List<Object?> get props => [];
}

class MoviesLoaded extends MoviesEvent {}

class MovieAdded extends MoviesEvent {
  final Movie movie;
  const MovieAdded(this.movie);
  @override
  List<Object> get props => [movie];
}

class MovieUpdated extends MoviesEvent {
  final Movie movie;
  const MovieUpdated(this.movie);
  @override
  List<Object> get props => [movie];
}

class MovieDeleted extends MoviesEvent {
  final int id;
  const MovieDeleted(this.id);
  @override
  List<Object> get props => [id];
}

class MoviesSearched extends MoviesEvent {
  final String query;
  const MoviesSearched(this.query);
  @override
  List<Object> get props => [query];
}

class MoviesState extends Equatable {
  final List<Movie> movies;
  final List<Movie> filteredMovies;
  final String searchQuery;
  final bool isLoading;

  const MoviesState({
    required this.movies,
    required this.filteredMovies,
    this.searchQuery = '',
    this.isLoading = false,
  });

  MoviesState copyWith({
    List<Movie>? movies,
    List<Movie>? filteredMovies,
    String? searchQuery,
    bool? isLoading,
  }) {
    return MoviesState(
      movies: movies ?? this.movies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [movies, filteredMovies, searchQuery, isLoading];
}

// BLoC
class MoviesBloc extends Bloc<MoviesEvent, MoviesState> {
  final MovieRepository _repository;

  MoviesBloc(this._repository)
      : super(const MoviesState(movies: [], filteredMovies: [], isLoading: true)) {
    on<MoviesLoaded>(_onMoviesLoaded);
    on<MovieAdded>(_onMovieAdded);
    on<MovieUpdated>(_onMovieUpdated);
    on<MovieDeleted>(_onMovieDeleted);
    on<MoviesSearched>(_onMoviesSearched);
  }

  Future<void> _onMoviesLoaded(MoviesLoaded event, Emitter<MoviesState> emit) async {
    emit(state.copyWith(isLoading: true));
    final movies = await _repository.getMovies();
    emit(state.copyWith(
      movies: movies,
      filteredMovies: _filter(movies, state.searchQuery),
      isLoading: false,
    ));
  }

  Future<void> _onMovieAdded(MovieAdded event, Emitter<MoviesState> emit) async {
    await _repository.insertMovie(event.movie);
    final movies = await _repository.getMovies();
    emit(state.copyWith(
      movies: movies,
      filteredMovies: _filter(movies, state.searchQuery),
    ));
  }

  Future<void> _onMovieUpdated(MovieUpdated event, Emitter<MoviesState> emit) async {
    await _repository.updateMovie(event.movie);
    final movies = await _repository.getMovies();
    emit(state.copyWith(
      movies: movies,
      filteredMovies: _filter(movies, state.searchQuery),
    ));
  }

  Future<void> _onMovieDeleted(MovieDeleted event, Emitter<MoviesState> emit) async {
    await _repository.deleteMovie(event.id);
    final movies = await _repository.getMovies();
    emit(state.copyWith(
      movies: movies,
      filteredMovies: _filter(movies, state.searchQuery),
    ));
  }

  void _onMoviesSearched(MoviesSearched event, Emitter<MoviesState> emit) {
    emit(state.copyWith(
      filteredMovies: _filter(state.movies, event.query),
      searchQuery: event.query,
    ));
  }

  List<Movie> _filter(List<Movie> list, String query) {
    if (query.isEmpty) return list;
    return list.where((m) =>
      m.title.toLowerCase().contains(query.toLowerCase()) ||
      m.genre.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}