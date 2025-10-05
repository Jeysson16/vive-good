import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsEnabled = false;
  
  // Audio Recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  
  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Stream controllers
  final StreamController<String> _speechResultController = StreamController<String>.broadcast();
  final StreamController<String> _partialSpeechController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  final StreamController<bool> _ttsStateController = StreamController<bool>.broadcast();
  
  // Getters for streams
  Stream<String> get speechResultStream => _speechResultController.stream;
  Stream<String> get partialSpeechStream => _partialSpeechController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<bool> get ttsStateStream => _ttsStateController.stream;
  
  // Getters for states
  bool get isListening => _speechToText.isListening;
  bool get isSpeechEnabled => _speechEnabled;
  bool get isTtsEnabled => _ttsEnabled;
  bool get isRecording => _isRecording;
  String get lastWords => _lastWords;
  
  /// Initialize voice services
  Future<bool> initialize() async {
    try {
      // Request permissions
      await _requestPermissions();
      
      // Initialize Speech to Text
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          _listeningController.add(false);
        },
        onStatus: (status) {
          _listeningController.add(status == 'listening');
        },
      );
      
      // Initialize Text to Speech
      await _initializeTts();
      
      return _speechEnabled && _ttsEnabled;
    } catch (e) {
      return false;
    }
  }
  
  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.speech,
    ];
    
    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        // Permission not granted
      }
    }
  }
  
  /// Initialize Text to Speech
  Future<void> _initializeTts() async {
    try {
      _ttsEnabled = true;
      
      // Configure TTS settings
      await _flutterTts.setLanguage('es-ES'); // Spanish
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        _ttsStateController.add(true);
      });
      
      _flutterTts.setCompletionHandler(() {
        _ttsStateController.add(false);
      });
      
      _flutterTts.setErrorHandler((message) {
        _ttsStateController.add(false);
      });
      
      // Platform-specific configurations
      if (Platform.isAndroid) {
        await _flutterTts.setEngine('com.google.android.tts');
      }
      
    } catch (e) {
      _ttsEnabled = false;
    }
  }
  
  /// Start listening for speech
  Future<void> startListening() async {
    if (!_speechEnabled) {
      print('DEBUG: Speech not enabled');
      return;
    }
    
    print('DEBUG: Starting speech recognition...');
    
    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          print('DEBUG: Speech result - Words: "${_lastWords}", Final: ${result.finalResult}, Confidence: ${result.confidence}');
          
          // Enviar resultados parciales para transcripción en tiempo real
          if (!result.finalResult) {
            print('DEBUG: Sending partial transcription: "$_lastWords"');
            _partialSpeechController.add(_lastWords);
          } else {
            // Resultado final - NO detener automáticamente
            print('DEBUG: Sending final speech result: "$_lastWords"');
            _speechResultController.add(_lastWords);
            _partialSpeechController.add(''); // Limpiar transcripción parcial
            // Continuar escuchando para más entrada del usuario
          }
        },
        listenFor: const Duration(minutes: 5), // Tiempo máximo extendido
        pauseFor: const Duration(seconds: 30), // Pausa mucho más larga antes de auto-stop
        partialResults: true, // Habilitar resultados parciales
        localeId: 'es_ES', // Spanish locale
        cancelOnError: false, // No cancelar por errores menores
        listenMode: ListenMode.dictation, // Modo dictado para escucha continua
        onSoundLevelChange: (level) {
          // Enviar nivel de sonido para animaciones
          _amplitudeController.add(level);
        },
      );
      
      _listeningController.add(true);
    } catch (e) {
      _listeningController.add(false);
    }
  }
  
  /// Stop listening for speech
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _listeningController.add(false);
    } catch (e) {
      // Error stopping speech recognition
    }
  }
  
  /// Speak text using TTS
  Future<void> speak(String text) async {
    print('DEBUG TTS: speak() called with text: "$text"');
    print('DEBUG TTS: _ttsEnabled: $_ttsEnabled, text.isEmpty: ${text.isEmpty}');
    
    if (!_ttsEnabled || text.isEmpty) {
      print('DEBUG TTS: Exiting early - TTS not enabled or text is empty');
      return;
    }
    
    try {
      print('DEBUG TTS: Stopping any ongoing speech...');
      await _flutterTts.stop(); // Stop any ongoing speech
      print('DEBUG TTS: Starting to speak text: "$text"');
      await _flutterTts.speak(text);
      print('DEBUG TTS: speak() command sent successfully');
    } catch (e) {
      print('DEBUG TTS: Error speaking text: $e');
      print('DEBUG TTS: Error stack trace: ${StackTrace.current}');
    }
  }
  
  /// Stop TTS
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _ttsStateController.add(false);
    } catch (e) {
      // Error stopping TTS
    }
  }
  
  /// Start audio recording
  Future<String?> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final path = '/tmp/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        
        _isRecording = true;
        _recordingPath = path;
        
        // Start amplitude monitoring
        _startAmplitudeMonitoring();
        
        return path;
      }
    } catch (e) {
      // Error starting recording
    }
    return null;
  }
  
  /// Stop audio recording
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _amplitudeController.add(0.0);
      return path;
    } catch (e) {
      // Error stopping recording
      return null;
    }
  }
  
  /// Start monitoring recording amplitude
  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      _audioRecorder.getAmplitude().then((amplitude) {
        final normalizedAmplitude = amplitude.current.clamp(0.0, 1.0);
        _amplitudeController.add(normalizedAmplitude);
      }).catchError((error) {
        // Error getting amplitude
      });
    });
  }
  
  /// Play audio file
  Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      // Error playing audio
    }
  }
  
  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Error stopping audio
    }
  }
  
  /// Get available speech recognition locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_speechEnabled) return [];
    return await _speechToText.locales();
  }
  
  /// Get available TTS voices
  Future<List<dynamic>> getAvailableVoices() async {
    if (!_ttsEnabled) return [];
    return await _flutterTts.getVoices;
  }
  
  /// Set TTS voice
  Future<void> setVoice(Map<String, String> voice) async {
    if (!_ttsEnabled) return;
    await _flutterTts.setVoice(voice);
  }
  
  /// Set TTS speech rate
  Future<void> setSpeechRate(double rate) async {
    if (!_ttsEnabled) return;
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }
  
  /// Set TTS pitch
  Future<void> setPitch(double pitch) async {
    if (!_ttsEnabled) return;
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }
  
  /// Set TTS volume
  Future<void> setVolume(double volume) async {
    if (!_ttsEnabled) return;
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopListening();
      await stopSpeaking();
      await stopRecording();
      await stopAudio();
      
      await _speechResultController.close();
      await _partialSpeechController.close();
      await _listeningController.close();
      await _amplitudeController.close();
      await _ttsStateController.close();
      
      await _audioRecorder.dispose();
      await _audioPlayer.dispose();
    } catch (e) {
      // Error disposing voice service
    }
  }
}