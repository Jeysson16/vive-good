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
      
      // Configure TTS settings with multiple Spanish variants
      bool languageSet = false;
      
      // Try different Spanish language codes, prioritizing Peruvian Spanish
      final spanishLanguages = ['es-PE', 'es-MX', 'es-AR', 'es-CO', 'es-CL', 'es-ES', 'es-US', 'es'];
      
      for (String lang in spanishLanguages) {
        try {
          final result = await _flutterTts.setLanguage(lang);
          if (result == 1) {
            print('TTS: Successfully set language to $lang');
            languageSet = true;
            break;
          }
        } catch (e) {
          print('TTS: Failed to set language $lang: $e');
        }
      }
      
      if (!languageSet) {
        print('TTS: Warning - Could not set Spanish language, using default');
      }
      
      // Try to find and set a Spanish voice
      try {
        print('TTS: Getting available voices...');
        final voices = await _flutterTts.getVoices;
        
        if (voices != null && voices.isNotEmpty) {
          print('TTS: Found ${voices.length} available voices');
          
          // Look for Spanish voices, prioritizing Peruvian and Latin American variants
          final spanishVoices = voices.where((voice) {
            try {
              final name = voice['name']?.toString().toLowerCase() ?? '';
              final locale = voice['locale']?.toString().toLowerCase() ?? '';
              return locale.startsWith('es') || 
                     name.contains('spanish') || 
                     name.contains('español') ||
                     name.contains('maria') ||
                     name.contains('diego') ||
                     name.contains('carmen') ||
                     name.contains('lucia') ||
                     name.contains('carlos') ||
                     name.contains('sofia');
            } catch (e) {
              print('TTS: Error processing voice data: $e');
              return false;
            }
          }).toList();
          
          print('TTS: Found ${spanishVoices.length} Spanish voices');
          
          if (spanishVoices.isNotEmpty) {
            // Sort voices to prioritize Peruvian and Latin American variants
            try {
              spanishVoices.sort((a, b) {
                try {
                  final localeA = a['locale']?.toString().toLowerCase() ?? '';
                  final localeB = b['locale']?.toString().toLowerCase() ?? '';
                  
                  // Prioritize Peruvian Spanish
                  if (localeA.contains('pe') && !localeB.contains('pe')) return -1;
                  if (!localeA.contains('pe') && localeB.contains('pe')) return 1;
                  
                  // Then prioritize other Latin American variants
                  final latinAmericanA = localeA.contains('mx') || localeA.contains('ar') || 
                                        localeA.contains('co') || localeA.contains('cl') ||
                                        localeA.contains('ve') || localeA.contains('ec') ||
                                        localeA.contains('bo') || localeA.contains('py') ||
                                        localeA.contains('uy');
                  final latinAmericanB = localeB.contains('mx') || localeB.contains('ar') || 
                                        localeB.contains('co') || localeB.contains('cl') ||
                                        localeB.contains('ve') || localeB.contains('ec') ||
                                        localeB.contains('bo') || localeB.contains('py') ||
                                        localeB.contains('uy');
                  
                  if (latinAmericanA && !latinAmericanB) return -1;
                  if (!latinAmericanA && latinAmericanB) return 1;
                  
                  return 0;
                } catch (e) {
                  print('TTS: Error sorting voices: $e');
                  return 0;
                }
              });
            } catch (e) {
              print('TTS: Error sorting Spanish voices: $e');
            }
            
            // Try to set the best Spanish voice
            for (int i = 0; i < spanishVoices.length; i++) {
              try {
                final selectedVoice = spanishVoices[i];
                final voiceMap = <String, String>{};
                
                // Safely convert each key-value pair to String
                selectedVoice.forEach((key, value) {
                  if (key != null && value != null) {
                    voiceMap[key.toString()] = value.toString();
                  }
                });
                
                if (voiceMap.isNotEmpty && voiceMap.containsKey('name')) {
                  await _flutterTts.setVoice(voiceMap);
                  final locale = voiceMap['locale'];
                  if (locale != null && locale.isNotEmpty) {
                    try {
                      await _flutterTts.setLanguage(locale);
                    } catch (_) {}
                  }
                  print('TTS: Successfully set Spanish voice: ${voiceMap['name']} (${voiceMap['locale'] ?? 'unknown locale'})');
                  break; // Exit loop on success
                } else {
                  print('TTS: Voice data incomplete for voice ${i + 1}, trying next...');
                }
              } catch (e) {
                print('TTS: Error setting voice ${i + 1}: $e');
                if (i == spanishVoices.length - 1) {
                  print('TTS: All Spanish voices failed, using default voice');
                }
              }
            }
          } else {
            print('TTS: No Spanish voices found, using default voice');
          }
        } else {
          print('TTS: No voices available or getVoices returned null');
        }
      } catch (e) {
        print('TTS: Critical error in voice configuration: $e');
        print('TTS: Continuing with default voice settings');
      }
      
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.setVolume(0.85);
      await _flutterTts.setPitch(0.98);
      try {
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (_) {}
      
      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        _ttsStateController.add(true);
      });
      
      _flutterTts.setCompletionHandler(() {
        _ttsStateController.add(false);
      });
      
      _flutterTts.setErrorHandler((message) {
        print('TTS Error: $message');
        _ttsStateController.add(false);
      });
      
      // Platform-specific configurations
      if (Platform.isAndroid) {
        await _flutterTts.setEngine('com.google.android.tts');
      }
      
    } catch (e) {
      print('TTS: Failed to initialize: $e');
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
      final locale = await _preferredSpeechLocale();
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          print('DEBUG: Speech result - Words: "$_lastWords", Final: ${result.finalResult}, Confidence: ${result.confidence}');
          
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
        localeId: locale,
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
      if (isListening) {
        try { await stopListening(); } catch (_) {}
      }
      if (_isRecording) {
        try { await stopRecording(); } catch (_) {}
      }
      await _flutterTts.stop(); // Stop any ongoing speech
      print('DEBUG TTS: Starting to speak text: "$text"');
      await _flutterTts.speak(text);
      print('DEBUG TTS: speak() command sent successfully');
    } catch (e) {
      print('DEBUG TTS: Error speaking text: $e');
      print('DEBUG TTS: Error stack trace: ${StackTrace.current}');
    }
  }

  Future<String> _preferredSpeechLocale() async {
    try {
      final locales = await _speechToText.locales();
      final spanish = locales.where((l) => l.localeId.toLowerCase().startsWith('es')).toList();
      if (spanish.isEmpty) return 'es_ES';
      final preferred = spanish.firstWhere(
        (l) => l.localeId.toLowerCase().contains('pe'),
        orElse: () => spanish.first,
      );
      return preferred.localeId;
    } catch (_) {
      return 'es_ES';
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
