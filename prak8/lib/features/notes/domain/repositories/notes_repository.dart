import '../entities/note_entity.dart';

abstract class NotesRepository {
  Future<void> addNote(String title, String description, String userEmail);
  Stream<List<NoteEntity>> getNotesStream();
  Future<void> deleteNote(String id);
}