class Movie {
  final int? id;
  final String title;
  final int year;
  final String genre;
  final String imageUrl;

  Movie({
    this.id,
    required this.title,
    required this.year,
    required this.genre,
    required this.imageUrl,
  });

  Movie copyWith({
    int? id,
    String? title,
    int? year,
    String? genre,
    String? imageUrl,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'genre': genre,
      'imageUrl': imageUrl,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] as int?,
      title: map['title'] as String,
      year: map['year'] as int,
      genre: map['genre'] as String,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}