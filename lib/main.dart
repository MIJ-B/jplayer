import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MediaPlayerApp());
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Player',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MediaPlayerService {
  static const platform = MethodChannel('com.mediamanager/scanner');

  static Future<List<Map<String, dynamic>>> scanVideos() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('scanVideos');
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error scanning videos: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> scanAudio() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('scanAudio');
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error scanning audio: $e');
      return [];
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      final video = await Permission.videos.request();
      final audio = await Permission.audio.request();
      
      setState(() {
        _permissionGranted = status.isGranted || video.isGranted || audio.isGranted;
      });
    }
  }

  final List<Widget> _screens = [
    const VideoScreen(),
    const AudioScreen(),
    const BrowseScreen(),
    const PlaylistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Audio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Playlists',
          ),
        ],
      ),
    );
  }
}

// VIDEO SCREEN
class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final videos = await MediaPlayerService.scanVideos();
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  void _sortVideos() {
    setState(() {
      if (_sortBy == 'name') {
        _videos.sort((a, b) => a['title'].compareTo(b['title']));
      } else if (_sortBy == 'date') {
        _videos.sort((a, b) => (b['dateAdded'] ?? 0).compareTo(a['dateAdded'] ?? 0));
      } else if (_sortBy == 'size') {
        _videos.sort((a, b) => (b['size'] ?? 0).compareTo(a['size'] ?? 0));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _sortVideos();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'size', child: Text('Sort by Size')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No videos found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadVideos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
                    ],
                  ),
                )
              : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return InkWell(
          onTap: () => _playVideo(video),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      video['thumbnail'] != null
                          ? Image.file(
                              File(video['thumbnail']),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultThumbnail(),
                            )
                          : _defaultThumbnail(),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(video['duration'] ?? 0),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'] ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSize(video['size'] ?? 0),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return ListTile(
          leading: SizedBox(
            width: 80,
            height: 60,
            child: video['thumbnail'] != null
                ? Image.file(
                    File(video['thumbnail']),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultThumbnail(),
                  )
                : _defaultThumbnail(),
          ),
          title: Text(
            video['title'] ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${_formatDuration(video['duration'] ?? 0)} • ${_formatSize(video['size'] ?? 0)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showVideoOptions(video),
          ),
          onTap: () => _playVideo(video),
        );
      },
    );
  }

  Widget _defaultThumbnail() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.video_library, size: 40, color: Colors.grey),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _playVideo(Map<String, dynamic> video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoPath: video['path']),
      ),
    );
  }

  void _showVideoOptions(Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play'),
            onTap: () {
              Navigator.pop(context);
              _playVideo(video);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Details'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// VIDEO PLAYER SCREEN (Full Screen)
class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentPosition = 0;
  double _volume = 1.0;
  double _brightness = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
      });

    _controller.addListener(() {
      setState(() {
        _currentPosition = _controller.value.position.inSeconds.toDouble();
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(),
            ),
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
          const Spacer(),
          // Play/Pause controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 40),
                color: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 64,
                ),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    _isPlaying ? _controller.pause() : _controller.play();
                    _isPlaying = !_isPlaying;
                  });
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 40),
                color: Colors.white,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _formatTime(_currentPosition.toInt()),
                  style: const TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: Slider(
                    value: _currentPosition,
                    max: _controller.value.duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      _controller.seekTo(Duration(seconds: value.toInt()));
                    },
                    activeColor: Colors.orange,
                    inactiveColor: Colors.grey,
                  ),
                ),
                Text(
                  _formatTime(_controller.value.duration.inSeconds),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      _volume = _volume > 0 ? 0 : 1;
                      _controller.setVolume(_volume);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  color: Colors.white,
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  color: Colors.white,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}

// AUDIO SCREEN
class AudioScreen extends StatefulWidget {
  const AudioScreen({Key? key}) : super(key: key);

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _loadAudio() async {
    setState(() => _isLoading = true);
    final songs = await MediaPlayerService.scanAudio();
    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  void _playSong(Map<String, dynamic> song) async {
    await _audioPlayer.play(DeviceFileSource(song['path']));
    setState(() {
      _currentSong = song;
      _isPlaying = true;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAudio,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentSong != null) _buildNowPlaying(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? const Center(child: Text('No audio files found'))
                    : ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          final isCurrentSong = _currentSong?['path'] == song['path'];
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              child: Icon(
                                isCurrentSong ? Icons.graphic_eq : Icons.music_note,
                                color: isCurrentSong ? Colors.orange : Colors.grey,
                              ),
                            ),
                            title: Text(
                              song['title'] ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrentSong ? Colors.orange : Colors.white,
                                fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${song['artist'] ?? 'Unknown Artist'} • ${song['album'] ?? 'Unknown Album'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              _formatDuration(song['duration'] ?? 0),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            onTap: () => _playSong(song),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withOpacity(0.3), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, size: 30, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSong?['title'] ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentSong?['artist'] ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 32,
                onPressed: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    await _audioPlayer.resume();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_formatPosition(_position), style: const TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  max: _duration.inSeconds.toDouble(),
                  onChanged: (value) async {
                    await _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: Colors.orange,
                  inactiveColor: Colors.grey,
                ),
              ),
              Text(_formatPosition(_duration), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds.remainder(60);
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPosition(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

// BROWSE SCREEN
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFolderTile('Internal Storage', '/storage/emulated/0', Icons.phone_android),
          _buildFolderTile('Downloads', '/storage/emulated/0/Download', Icons.download),
          _buildFolderTile('Movies', '/storage/emulated/0/Movies', Icons.movie),
          _buildFolderTile('Music', '/storage/emulated/0/Music', Icons.music_note),
          _buildFolderTile('DCIM', '/storage/emulated/0/DCIM', Icons.camera_alt),
          _buildFolderTile('Documents', '/storage/emulated/0/Documents', Icons.folder),
        ],
      ),
    );
  }

  Widget _buildFolderTile(String title, String path, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        subtitle: Text(path, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

// PLAYLIST SCREEN
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playlists = [
      {'name': 'Favorites', 'count': 0, 'icon': Icons.favorite},
      {'name': 'Recently Played', 'count': 0, 'icon': Icons.history},
      {'name': 'Most Played', 'count': 0, 'icon': Icons.trending_up},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: Icon(playlist['icon'] as IconData, color: Colors.orange),
              ),
              title: Text(playlist['name'] as String),
              subtitle: Text('${playlist['count']} items'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}