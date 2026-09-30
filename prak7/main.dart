import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:location/location.dart' as loc;

class MediaItem {
  final int? id;
  final String type; // 'photo', 'video', 'audio'
  final String title;
  final String url;
  final double? latitude; 
  final double? longitude;
  final String createdAt;

  MediaItem({
    this.id,
    required this.type,
    required this.title,
    required this.url,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'url': url,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int?,
      type: map['type'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }
}

class MediaDatabase {
  static final MediaDatabase instance = MediaDatabase._init();
  static Database? _database;
  static const String _webStorageKey = 'multimedia_feed_items';

  MediaDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('multimedia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE media (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<MediaItem>> getAllMedia() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webStorageKey);
      if (data == null) {
        return _getInitialSamples();
      }
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e))).toList();
    } else {
      final db = await instance.database;
      final result = await db.query('media', orderBy: 'id DESC');
      if (result.isEmpty) {
        for (var item in _getInitialSamples()) {
          await db.insert('media', item.toMap());
        }
        final fresh = await db.query('media', orderBy: 'id DESC');
        return fresh.map((json) => MediaItem.fromMap(json)).toList();
      }
      return result.map((json) => MediaItem.fromMap(json)).toList();
    }
  }

  Future<int> insertMedia(MediaItem item) async {
    if (kIsWeb) {
      final items = await getAllMedia();
      final newItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch,
        type: item.type,
        title: item.title,
        url: item.url,
        latitude: item.latitude,
        longitude: item.longitude,
        createdAt: item.createdAt,
      );
      items.insert(0, newItem);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webStorageKey, jsonEncode(items.map((e) => e.toMap()).toList()));
      return newItem.id!;
    } else {
      final db = await instance.database;
      return await db.insert('media', item.toMap());
    }
  }

  Future<int> deleteMedia(int id) async {
    if (kIsWeb) {
      final items = await getAllMedia();
      items.removeWhere((element) => element.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webStorageKey, jsonEncode(items.map((e) => e.toMap()).toList()));
      return 1;
    } else {
      final db = await instance.database;
      return await db.delete('media', where: 'id = ?', whereArgs: [id]);
    }
  }


  List<MediaItem> _getInitialSamples() {
    return [
      MediaItem(
        id: 1,
        type: 'photo',
        title: 'Учебный корпус РЭУ им. Плеханова (МПТ)',
        url: 'https://avatars.mds.yandex.net/get-altay/947364/2a00000184f5507821ea057ca896fc270dad/orig',
        latitude: 55.7297,
        longitude: 37.6293,
        createdAt: 'Только что',
      ),
      MediaItem(
        id: 2,
        type: 'video',
        title: 'Пример видеоролика с контролем перемотки',
        url: 'https://www.shutterstock.com/shutterstock/videos/4036919727/preview/stock-footage-silhouette-of-a-stray-cat-on-rocky-coastline-looking-around-against-bright-sunset-sun-with-lens.webm',
        createdAt: '1 час назад',
      ),
      MediaItem(
        id: 3,
        type: 'audio',
        title: 'Аудиотрек: Instrumental Demo',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        createdAt: 'Сегодня',
      ),
    ];
  }
  }

class GeoService {
  static Future<loc.LocationData?> getCurrentLocation() async {
    try {
      final location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return null;
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return null;
      }

      return await location.getLocation();
    } catch (e) {
      return null;
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultimediaApp());
}

class MultimediaApp extends StatelessWidget {
  const MultimediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Media Feed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: const FeedScreen(),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<MediaItem> _feed = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final data = await MediaDatabase.instance.getAllMedia();
    setState(() {
      _feed = data;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Добавить публикацию в ленту',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.photo_camera, color: Colors.white),
              ),
              title: const Text('Фотография с геопозицией (location)'),
              subtitle: const Text('Зафиксировать GPS-координаты в SQLite'),
              onTap: () {
                Navigator.pop(ctx);
                _openMediaInputDialog('photo');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.video_library, color: Colors.white),
              ),
              title: const Text('Видеоролик с перемоткой'),
              subtitle: const Text('Воспроизведение и перемотка (видеоплеер)'),
              onTap: () {
                Navigator.pop(ctx);
                _openMediaInputDialog('video');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.audiotrack, color: Colors.white),
              ),
              title: const Text('Аудиотрек (аудио-проигрыватель)'),
              subtitle: const Text('Воспроизведение аудио по ссылке'),
              onTap: () {
                Navigator.pop(ctx);
                _openMediaInputDialog('audio');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openMediaInputDialog(String type) async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    double? detectedLat;
    double? detectedLng;
    bool isLocating = false;

    if (type == 'photo') {
      isLocating = true;
      final locData = await GeoService.getCurrentLocation();
      detectedLat = locData?.latitude ?? 55.7558;
      detectedLng = locData?.longitude ?? 37.6173;
      isLocating = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(
            type == 'photo'
                ? 'Новое фото'
                : type == 'video'
                    ? 'Новое видео'
                    : 'Новый аудиотрек',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Описание / Название'),
                ),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'URL-ссылка на ресурс',
                    hintText: type == 'photo'
                        ? 'https://...jpg'
                        : type == 'video'
                            ? 'https://...mp4'
                            : 'https://...mp3',
                  ),
                ),
                const SizedBox(height: 12),
                if (type == 'photo')
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLocating
                                ? 'Определение GPS...'
                                : 'Геопозиция: ${detectedLat?.toStringAsFixed(4)}, ${detectedLng?.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                String url = urlCtrl.text.trim();

                if (url.isEmpty) {
                  if (type == 'photo') url = 'https://avatars.mds.yandex.net/get-altay/947364/2a00000184f5507821ea057ca896fc270dad/orig';
                  if (type == 'video') url = 'https://vkvideo.ru/video-41593074_456239019';
                  if (type == 'audio') url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
                }

                final item = MediaItem(
                  type: type,
                  title: title.isEmpty ? 'Медиа-публикация' : title,
                  url: url,
                  latitude: detectedLat,
                  longitude: detectedLng,
                  createdAt: 'Только что',
                );

                await MediaDatabase.instance.insertMedia(item);
                if (mounted) {
                  Navigator.pop(dlgCtx);
                  _loadFeed();
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _feed.length,
              itemBuilder: (context, index) {
                final item = _feed[index];
                return InstagramCard(
                  item: item,
                  onDelete: () async {
                    await MediaDatabase.instance.deleteMedia(item.id!);
                    _loadFeed();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class InstagramCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onDelete;

  const InstagramCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка публикации
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Icon(
                    item.type == 'photo'
                        ? Icons.person
                        : item.type == 'video'
                            ? Icons.videocam
                            : Icons.music_note,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (item.latitude != null && item.longitude != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.redAccent),
                            const SizedBox(width: 2),
                            Text(
                              'GPS: ${item.latitude!.toStringAsFixed(3)}, ${item.longitude!.toStringAsFixed(3)}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          // Мультимедийное тело публикации
          if (item.type == 'photo')
            Image.network(
              item.url,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                height: 250,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            )
          else if (item.type == 'video')
            VideoPlayerWidget(videoUrl: item.url)
          else if (item.type == 'audio')
            AudioPlayerWidget(audioUrl: item.url, title: item.title),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.favorite_border),
                    SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline),
                    SizedBox(width: 16),
                    Icon(Icons.send_outlined),
                    Spacer(),
                    Icon(Icons.bookmark_border),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Опубликовано: ${item.createdAt}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
@override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        // Убираем звук на старте, чтобы Chrome не блокировал воспроизведение
        _controller.setVolume(0.0);
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }).catchError((error) {
        print("Ошибка загрузки видео: $error");
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Перемотка на заданные секунды вперед / назад
  void _seekRelative(int seconds) {
    final current = _controller.value.position;
    final target = current + Duration(seconds: seconds);
    _controller.seekTo(target);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 250,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final duration = _controller.value.duration;
    final position = _controller.value.position;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          // Панель управления и перемотки видео
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                // Ползунок точной перемотки видеоролика
                Slider(
                  value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                  max: duration.inMilliseconds.toDouble(),
                  activeColor: Colors.deepPurpleAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) {
                    _controller.seekTo(Duration(milliseconds: val.toInt()));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Перемотка назад на 10 сек
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () => _seekRelative(-10),
                    ),
                    // Кнопка воспроизведения / паузы
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: () {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      },
                    ),
                    // Перемотка вперед на 10 сек
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => _seekRelative(10),
                    ),
                    const Spacer(),
                    // Таймер
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String title;

  const AudioPlayerWidget({super.key, required this.audioUrl, required this.title});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: Colors.deepPurple, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Slider(
            value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
            max: (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
            activeColor: Colors.deepPurple,
            onChanged: (val) {
              _audioPlayer.seek(Duration(milliseconds: val.toInt()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(_position), style: const TextStyle(fontSize: 12)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                    iconSize: 40,
                    color: Colors.deepPurple,
                    onPressed: () async {
                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        await _audioPlayer.play(UrlSource(widget.audioUrl));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    color: Colors.grey,
                    onPressed: () async {
                      await _audioPlayer.stop();
                      setState(() => _position = Duration.zero);
                    },
                  ),
                ],
              ),
              Text(_formatTime(_duration), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}