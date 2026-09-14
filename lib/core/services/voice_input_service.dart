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

  Future<bool> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(double soundLevel)? onSoundLevel,
    void Function(VoiceInputStatus status)? onStatus,
    void Function(String errorMessage)? onError,
    String? localeId,
  }) async {
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
    onStatusUpdate?.call(_status);

    final effectiveLocale = localeId ?? _vietnameseLocaleId ?? 'vi_VN';

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (currentSession == _activeSessionId) {
            _handleResult(result, currentSession);
          }
        },
        listenFor: const Duration(seconds: 40),
        pauseFor: const Duration(seconds: 4),
        localeId: effectiveLocale,
        onSoundLevelChange: (level) {
          if (currentSession == _activeSessionId) {
            _handleSoundLevel(level);
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (e) {
      if (currentSession != _activeSessionId) return false;
      debugPrint('VoiceInputService startListening error: $e');
      _status = VoiceInputStatus.error;
      onStatusUpdate?.call(_status);
      onErrorUpdate?.call('Lỗi khi bắt đầu nghe: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    _activeSessionId++;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _status = VoiceInputStatus.stopped;
    onStatusUpdate?.call(_status);
  }

  Future<void> cancelListening() async {
    _activeSessionId++;
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
    _status = VoiceInputStatus.idle;
    onStatusUpdate?.call(_status);
  }

  void _handleResult(SpeechRecognitionResult result, int sessionId) {
    if (sessionId != _activeSessionId) return;
    onTranscriptUpdate?.call(
      result.recognizedWords,
      result.finalResult,
    );
  }

  void _handleSoundLevel(double level) {
    _soundLevel = level;
    onSoundLevelUpdate?.call(level);
  }

  void _handleStatus(String status) {
    debugPrint('SpeechToText status: $status');
    if (status == 'listening') {
      _status = VoiceInputStatus.listening;
    } else if (status == 'notListening' || status == 'done') {
      _status = VoiceInputStatus.stopped;
    }
    onStatusUpdate?.call(_status);
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('SpeechToText error: ${error.errorMsg} (permanent: ${error.permanent})');
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
    cancelListening();
    onTranscriptUpdate = null;
    onSoundLevelUpdate = null;
    onStatusUpdate = null;
    onErrorUpdate = null;
  }
}
