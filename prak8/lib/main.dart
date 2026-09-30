import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'firebase_options.dart';


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

// Интерфейс репозитория авторизации
abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password);
  Future<void> signOut();
  User? getCurrentUser();
}

// Интерфейс репозитория заметок Firestore
abstract class NotesRepository {
  Future<void> addNote(String title, String description, String userEmail);
  Stream<List<NoteEntity>> getNotesStream();
  Future<void> deleteNote(String id);
}


// DTO-модель заметки для Cloud Firestore
class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.title,
    required super.description,
    required super.userEmail,
    required super.createdAt,
  });

  factory NoteModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NoteModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      createdAt: data['createdAt'] as String? ?? '',
    );
  }
}

// Реализация работы с Firebase Authentication
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<User?> signIn(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  @override
  Future<User?> signUp(String email, String password) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  User? getCurrentUser() => _firebaseAuth.currentUser;
}

// Реализация работы с Cloud Firestore
class NotesRepositoryImpl implements NotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> addNote(String title, String description, String userEmail) async {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
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

final sl = GetIt.instance;

void initDependencies() {
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<NotesRepository>(() => NotesRepositoryImpl());
}


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthRepository _auth = sl<AuthRepository>();

  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните Email и пароль')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _auth.signIn(email, pass);
      } else {
        await _auth.signUp(email, pass);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NotesScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Вход в аккаунт' : 'Регистрация'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 16),
              Text(
                _isLogin ? 'Авторизация в Firebase' : 'Создание аккаунта',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль (от 6 символов)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? 'Нет аккаунта? Зарегистрироваться'
                      : 'Уже есть учетная запись? Войти'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Экран базы данных Firestore
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesRepository _notes = sl<NotesRepository>();
  final AuthRepository _auth = sl<AuthRepository>();

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая запись в Firestore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final desc = descCtrl.text.trim();
              final email = _auth.getCurrentUser()?.email ?? 'anonymous';

              if (title.isNotEmpty) {
                await _notes.addNote(title, desc, email);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Firestore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.deepOrange.shade50,
            child: Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Пользователь: ${user?.email ?? "Не авторизован"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NoteEntity>>(
              stream: _notes.getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notes = snapshot.data ?? [];
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('В Firestore пока нет записей.\nНажмите +, чтобы добавить документ.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(note.description),
                            const SizedBox(height: 6),
                            Text(
                              'Создано: ${note.createdAt} (${note.userEmail})',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _notes.deleteNote(note.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация сервисов Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Инициализация контейнера GetIt
  initDependencies();
  
  runApp(const FirebaseCleanApp());
}

class FirebaseCleanApp extends StatelessWidget {
  const FirebaseCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = sl<AuthRepository>();
    final currentUser = authRepository.getCurrentUser();

    return MaterialApp(
      title: 'Firebase Clean App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
      ),
      // Если пользователь уже входил, сразу открываем заметки, иначе форму входа
      home: currentUser != null ? const NotesScreen() : const AuthScreen(),
    );
  }
}