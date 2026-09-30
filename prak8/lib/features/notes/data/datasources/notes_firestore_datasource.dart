import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  final FirebaseFirestore _firestore;

  NotesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> addNote(String title, String description, String userEmail) async {
    final now = DateTime.now();
    final dateStr = '${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute}';
    
    await _firestore.collection('notes').add({
      'title': title,
      'description': description,
      'userEmail': userEmail,
      'createdAt': dateStr,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<NoteEntity>> getNotesStream() {
    return _firestore
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NoteModel.fromSnapshot(doc)).toList());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _firestore.collection('notes').doc(id).delete();
  }
}