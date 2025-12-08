import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/core/widgets/global_share_button.dart';

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

    _audioPath =
        'audio/${_day}_$_deity${_deity == "hanuman" ? "_chalisa" : "_aarti"}.mp3';
  }

  Future<void> _autoPlayMantra() async {
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(_audioPath));
    } catch (e) {}
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
          GlobalShareButton(currentPage: "darshan"), // ⭐ SHARE BUTTON ADDED
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

          // ⭐ BANNER AD SAFE SPACE
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
                border: Border.all(color: Colors.deepOrange, width: 1.0),
              ),
              child: const BannerAdWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
