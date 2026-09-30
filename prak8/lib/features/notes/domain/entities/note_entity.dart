class NoteEntity {
  final String id;
  final String title;
  final String description;
  final String userEmail;
  final String createdAt;

  const NoteEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.userEmail,
    required this.createdAt,
  });
}