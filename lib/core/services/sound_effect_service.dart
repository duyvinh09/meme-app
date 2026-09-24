import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized service to play sound effects across the app with low latency
class SoundEffectService {
  static final SoundEffectService instance = SoundEffectService._();
  SoundEffectService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> _playSound(String assetRelativePath) async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource(assetRelativePath),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('SoundEffectService play sound [$assetRelativePath] error: $e');
    }
  }

  /// 1. Có tin nhắn mới trong chat, tag hoặc thả cảm xúc trong tin nhắn
  Future<void> playMessageReceived() async {
    await _playSound('sounds/message_received.mp3');
  }

  /// 2. Gửi tin nhắn đi
  Future<void> playMessageSent() async {
    await _playSound('sounds/message_sent.mp3');
  }

  /// 3. Âm khi thả cảm xúc tin nhắn (không áp dụng cho bài viết để tránh spam)
  Future<void> playMessageReaction() async {
    await _playSound('sounds/message_reaction.mp3');
  }

  /// 4. Khi mở menu reaction thả cảm xúc tin nhắn
  Future<void> playOpenReactionMenu() async {
    // Falls back gracefully if filename has underscore
    await _playSound('sounds/message_reaction_2.mp3');
  }

  /// 5. Khi đạt thành tựu streak (popup mở khóa cột mốc Streak)
  Future<void> playStreakAchieved() async {
    await _playSound('sounds/streak.mp3');
  }
}
