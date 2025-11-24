import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

class DarshanPage extends StatefulWidget {
  const DarshanPage({super.key});

  @override
  State<DarshanPage> createState() => _DarshanPageState();
}

class _DarshanPageState extends State<DarshanPage>
    with SingleTickerProviderStateMixin {
  late String _day;
  late String _deity;
  late String _imagePath;
  late String _audioPath;

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // 🎧 Ensure proper audio playback context
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {},
        ),
      ),
    );

    _setDayData();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // 🔊 Auto play mantra when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPlayMantra();
    });
  }

  void _setDayData() {
    final weekday = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    _day = weekday;

    final deityMap = {
      'monday': 'shiva',
      'tuesday': 'hanuman',
      'wednesday': 'ganesha',
      'thursday': 'vishnu',
      'friday': 'lakshmi',
      'saturday': 'shani',
      'sunday': 'surya',
    };

    _deity = deityMap[_day] ?? 'shiva';
    _imagePath = 'assets/images/${_day}_$_deity.png';

    // ✅ no 'assets/' prefix here
    _audioPath =
        'audio/${_day}_$_deity${_deity == "hanuman" ? "_chalisa" : "_aarti"}.mp3';
  }

  Future<void> _autoPlayMantra() async {
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.loop);

      debugPrint("🎧 Playing: $_audioPath");
      // ✅ direct clean relative path
      await _player.play(AssetSource(_audioPath));
    } catch (e) {
      debugPrint("❌ Audio play error: $e");
    }
  }

  Future<void> _toggleMute() async {
    await _player.setVolume(_isMuted ? 1.0 : 0.0);
    setState(() => _isMuted = !_isMuted);
  }

  @override
  void dispose() {
    _player.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text(
          "${_day[0].toUpperCase()}${_day.substring(1)} Darshan",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _toggleMute,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🕉️ Animated deity image
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _scaleAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnim.value,
                    child: Image.asset(_imagePath, fit: BoxFit.contain),
                  );
                },
              ),
            ),
          ),

          // 🔔 Text info section
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
              border: Border.all(color: Colors.deepOrange, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔱 Mini mantra icon
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.deepOrange,
                  size: 22,
                ),

                const SizedBox(width: 10),

                // 🔊 Animated mantra text
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + (_scaleAnim.value - 1) * 0.4,
                      child: const Text(
                        "Mantra is Playing...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 📺 Silent ad section
          Container(
            height: 60,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: const Center(
              child: Text(
                "Ad space (silent)",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
