import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  
  final StreamController<String> _speechResultController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakingStateController = StreamController<bool>.broadcast();
  final StreamController<double> _soundLevelController = StreamController<double>.broadcast();
  
  Stream<String> get speechResultStream => _speechResultController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<bool> get speakingStateStream => _speakingStateController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get speechEnabled => _speechEnabled;

  Future<void> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          _stopListening();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _stopListening();
          }
        },
      );
      
      await _initializeTts();
      
    } catch (e) {
      _speechEnabled = false;
    }
  }
  
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingStateController.add(true);
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingStateController.add(false);
    });
    
    _flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
      _speakingStateController.add(false);
    });
  }

  Future<void> startListening() async {
    if (!_speechEnabled || _isListening) return;
    
    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _speechResultController.add(result.recognizedWords);
            _stopListening();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'es_ES',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        onSoundLevelChange: (level) {
          _soundLevelController.add(level);
        },
      );
      
      _isListening = true;
      _listeningStateController.add(true);
    } catch (e) {
      _stopListening();
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _stopListening();
  }
  
  void _stopListening() {
    _isListening = false;
    _listeningStateController.add(false);
    _soundLevelController.add(0.0);
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      _speakingStateController.add(false);
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _speakingStateController.add(false);
  }

  Future<void> pauseSpeaking() async {
    await _flutterTts.pause();
  }

  Future<void> resumeSpeaking() async {
    // Note: resume is not available in flutter_tts
    // This is a placeholder for future implementation
  }

  void dispose() {
    _speechResultController.close();
    _listeningStateController.close();
    _speakingStateController.close();
    _soundLevelController.close();
    _flutterTts.stop();
  }
}