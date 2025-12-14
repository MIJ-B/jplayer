import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MediaPlayerApp());
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Video',
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
            label: 'Playlist',
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
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  final List<Map<String, String>> _videos = [
    {
      'title': 'Sample Video 1',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
    {
      'title': 'Sample Video 2',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    },
  ];

  void _playVideo(String url) {
    _controller?.dispose();
    _controller = VideoPlayerController.network(url)
      ..initialize().then((_) {
        setState(() {});
        _controller!.play();
        _isPlaying = true;
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          if (_controller != null && _controller!.value.isInitialized)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _isPlaying ? _controller!.pause() : _controller!.play();
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    setState(() {
                      _controller!.pause();
                      _controller!.seekTo(Duration.zero);
                      _isPlaying = false;
                    });
                  },
                ),
              ],
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.video_file),
                  title: Text(_videos[index]['title']!),
                  onTap: () => _playVideo(_videos[index]['url']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// AUDIO SCREEN
class AudioScreen extends StatefulWidget {
  const AudioScreen({Key? key}) : super(key: key);

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _currentSong = '';

  final List<Map<String, String>> _songs = [
    {'title': 'Song 1', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'},
    {'title': 'Song 2', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'},
    {'title': 'Song 3', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'},
  ];

  void _playSong(String title, String url) async {
    await _audioPlayer.play(UrlSource(url));
    setState(() {
      _isPlaying = true;
      _currentSong = title;
    });
  }

  void _pauseSong() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopSong() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentSong = '';
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
      appBar: AppBar(title: const Text('Audio')),
      body: Column(
        children: [
          if (_currentSong.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.blue.withOpacity(0.2),
              child: Column(
                children: [
                  const Icon(Icons.music_note, size: 60),
                  const SizedBox(height: 10),
                  Text(_currentSong, style: const TextStyle(fontSize: 18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        iconSize: 40,
                        onPressed: _isPlaying ? _pauseSong : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        iconSize: 40,
                        onPressed: _stopSong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.audio_file),
                  title: Text(_songs[index]['title']!),
                  trailing: _currentSong == _songs[index]['title']
                      ? const Icon(Icons.equalizer, color: Colors.blue)
                      : null,
                  onTap: () => _playSong(
                    _songs[index]['title']!,
                    _songs[index]['url']!,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// BROWSE SCREEN
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategory(Icons.video_library, 'Videos', Colors.red),
          _buildCategory(Icons.music_note, 'Music', Colors.blue),
          _buildCategory(Icons.folder, 'Documents', Colors.orange),
          _buildCategory(Icons.image, 'Images', Colors.green),
          _buildCategory(Icons.download, 'Downloads', Colors.purple),
          _buildCategory(Icons.star, 'Favorites', Colors.yellow),
        ],
      ),
    );
  }

  Widget _buildCategory(IconData icon, String title, Color color) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
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
      {'name': 'My Favorites', 'count': '12 songs'},
      {'name': 'Workout Mix', 'count': '25 songs'},
      {'name': 'Chill Vibes', 'count': '18 songs'},
      {'name': 'Road Trip', 'count': '30 songs'},
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
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.playlist_play),
            ),
            title: Text(playlists[index]['name']!),
            subtitle: Text(playlists[index]['count']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          );
        },
      ),
    );
  }
}
