import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceInputStatus {
  idle,
  initializing,
  listening,
  processing,
  stopped,
  interrupted,
  error,
}

class VoiceInputService {
  VoiceInputService._internal();
  static final VoiceInputService _instance = VoiceInputService._internal();
  static VoiceInputService get instance => _instance;

  final SpeechToText _speechToText = SpeechToText();

  int _activeSessionId = 0;
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  bool get isListening => _speechToText.isListening;

  VoiceInputStatus _status = VoiceInputStatus.idle;
  VoiceInputStatus get status => _status;

  String? _vietnameseLocaleId;
  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  bool _hasSpoken = false;
  Timer? _initialSilenceTimer;
  Timer? _silenceTimer;

  // Timeout configurations:
  // 1. Initial silence timeout: 3s (Tự động tắt sau 3s nếu người dùng không nói gì từ đầu)
  // 2. Silence timeout after speaking: 2s (Tự động tắt sau 2s khi người dùng ngừng nói)
  static const Duration initialSilenceDuration = Duration(seconds: 3);
  static const Duration postSpeechSilenceDuration = Duration(seconds: 2);

  void Function(String words, bool isFinal)? onTranscriptUpdate;
  void Function(double soundLevel)? onSoundLevelUpdate;
  void Function(VoiceInputStatus status)? onStatusUpdate;
  void Function(String errorMessage)? onErrorUpdate;

  Future<bool> init() async {
    if (_isAvailable) return true;

    _status = VoiceInputStatus.initializing;
    onStatusUpdate?.call(_status);

    try {
      _isAvailable = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: kDebugMode,
      );

      if (_isAvailable) {
        final locales = await _speechToText.locales();
        for (final loc in locales) {
          final idLower = loc.localeId.toLowerCase();
          if (idLower.contains('vi') || idLower.contains('viet')) {
            _vietnameseLocaleId = loc.localeId;
            break;
          }
        }
        _vietnameseLocaleId ??= 'vi_VN';
      }

      _status = _isAvailable ? VoiceInputStatus.idle : VoiceInputStatus.error;
      onStatusUpdate?.call(_status);
      return _isAvailable;
    } catch (e) {
      debugPrint('VoiceInputService init error: $e');
      _status = VoiceInputStatus.error;
      onStatusUpdate?.call(_status);
      onErrorUpdate?.call('Không thể khởi tạo nhận diện giọng nói: $e');
      return false;
    }
  }

  /// Ngắt voice hiện tại (ví dụ khi người khác bật voice hoặc có session voice mới)
  Future<void> interrupt({String reason = 'interrupted_by_other'}) async {
    _cancelTimers();
    _activeSessionId++;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _status = VoiceInputStatus.interrupted;
    onStatusUpdate?.call(_status);
  }

  Future<bool> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(double soundLevel)? onSoundLevel,
    void Function(VoiceInputStatus status)? onStatus,
    void Function(String errorMessage)? onError,
    String? localeId,
  }) async {
    // 1. Tự động ngắt session voice cũ nếu có người khác bật voice mới
    _cancelTimers();
    _activeSessionId++;
    final currentSession = _activeSessionId;

    onTranscriptUpdate = onResult;
    onSoundLevelUpdate = onSoundLevel;
    onStatusUpdate = onStatus;
    onErrorUpdate = onError;

    if (!_isAvailable) {
      final inited = await init();
      if (!inited) {
        if (currentSession == _activeSessionId) {
          onError?.call('Nhận diện giọng nói chưa sẵn sàng trên thiết bị.');
        }
        return false;
      }
    }

    if (_speechToText.isListening) {
      await _speechToText.cancel();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (currentSession != _activeSessionId) return false;

    _status = VoiceInputStatus.listening;
    _hasSpoken = false;
    onStatusUpdate?.call(_status);

    final effectiveLocale = localeId ?? _vietnameseLocaleId ?? 'vi_VN';

    // 2. Bắt đầu Timer 5s: Nếu người dùng không nói gì ngay từ đầu -> ngắt sau 5s
    _initialSilenceTimer = Timer(initialSilenceDuration, () {
      if (currentSession == _activeSessionId && !_hasSpoken && _status == VoiceInputStatus.listening) {
        debugPrint('[VoiceInputService] 5s initial silence timeout reached. Auto stopping.');
        stopListening();
      }
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (currentSession == _activeSessionId) {
            _handleResult(result, currentSession);
          }
        },
        onSoundLevelChange: (level) {
          if (currentSession == _activeSessionId) {
            _handleSoundLevel(level, currentSession);
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          pauseFor: postSpeechSilenceDuration,
          localeId: effectiveLocale,
        ),
      );
      return true;
    } catch (e) {
      if (currentSession != _activeSessionId) return false;
      _cancelTimers();
      debugPrint('VoiceInputService startListening error: $e');
      _status = VoiceInputStatus.error;
      onStatusUpdate?.call(_status);
      onErrorUpdate?.call('Lỗi khi bắt đầu nghe: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    _cancelTimers();
    _activeSessionId++;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _status = VoiceInputStatus.stopped;
    onStatusUpdate?.call(_status);
  }

  Future<void> cancelListening() async {
    _cancelTimers();
    _activeSessionId++;
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
    _status = VoiceInputStatus.idle;
    onStatusUpdate?.call(_status);
  }

  void _handleResult(SpeechRecognitionResult result, int sessionId) {
    if (sessionId != _activeSessionId) return;

    final words = result.recognizedWords;
    if (words.trim().isNotEmpty) {
      _markSpeechStartedAndResetSilence(sessionId);
    }

    onTranscriptUpdate?.call(
      words,
      result.finalResult,
    );

    if (result.finalResult) {
      _cancelTimers();
      _status = VoiceInputStatus.stopped;
      onStatusUpdate?.call(_status);
    }
  }

  void _handleSoundLevel(double level, int sessionId) {
    if (sessionId != _activeSessionId) return;
    _soundLevel = level;
    onSoundLevelUpdate?.call(level);

    // Phát hiện mức âm thanh có tiếng nói
    final isVoiceLevel = (level > 2.0) || (level > -25.0 && level < 0);
    if (isVoiceLevel && _hasSpoken) {
      _resetSilenceTimer(sessionId);
    }
  }

  void _markSpeechStartedAndResetSilence(int sessionId) {
    if (sessionId != _activeSessionId) return;

    if (!_hasSpoken) {
      _hasSpoken = true;
      _initialSilenceTimer?.cancel();
      _initialSilenceTimer = null;
    }

    _resetSilenceTimer(sessionId);
  }

  void _resetSilenceTimer(int sessionId) {
    if (sessionId != _activeSessionId || _status != VoiceInputStatus.listening) return;

    _silenceTimer?.cancel();
    // 3. Khi người dùng đang nói mà bỗng dưng ngừng voice thì sau 3s sẽ tự động tắt voice
    _silenceTimer = Timer(postSpeechSilenceDuration, () {
      if (sessionId == _activeSessionId && _status == VoiceInputStatus.listening) {
        debugPrint('[VoiceInputService] 3s silence after speech reached. Auto stopping.');
        stopListening();
      }
    });
  }

  void _cancelTimers() {
    _initialSilenceTimer?.cancel();
    _initialSilenceTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _handleStatus(String status) {
    debugPrint('SpeechToText status: $status');
    if (status == 'listening') {
      _status = VoiceInputStatus.listening;
    } else if (status == 'notListening' || status == 'done') {
      _cancelTimers();
      _status = VoiceInputStatus.stopped;
    }
    onStatusUpdate?.call(_status);
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('SpeechToText error: ${error.errorMsg} (permanent: ${error.permanent})');
    _cancelTimers();
    final msg = error.errorMsg.toLowerCase();
    // Ignore transitional cancel/busy/no_match or timeout errors during user silence/switches
    if (msg.contains('busy') ||
        msg.contains('client') ||
        msg.contains('no_match') ||
        msg.contains('timeout') ||
        msg.contains('error_speech_timeout')) {
      _status = VoiceInputStatus.stopped;
      onStatusUpdate?.call(_status);
      return;
    }
    _status = VoiceInputStatus.error;
    onStatusUpdate?.call(_status);
    onErrorUpdate?.call(error.errorMsg);
  }

  void dispose() {
    _cancelTimers();
    cancelListening();
    onTranscriptUpdate = null;
    onSoundLevelUpdate = null;
    onStatusUpdate = null;
    onErrorUpdate = null;
  }
}
