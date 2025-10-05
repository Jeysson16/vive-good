enum VoiceAnimationStatus {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceAnimationState {
  final VoiceAnimationStatus status;
  final double amplitude;
  final double frequency;
  final List<double> waveformData;
  final Duration duration;
  final bool isRecording;
  final bool isPlaying;
  final double volume;
  final String? errorMessage;

  const VoiceAnimationState({
    required this.status,
    this.amplitude = 0.0,
    this.frequency = 1.0,
    this.waveformData = const [],
    this.duration = Duration.zero,
    this.isRecording = false,
    this.isPlaying = false,
    this.volume = 0.0,
    this.errorMessage,
  });

  VoiceAnimationState copyWith({
    VoiceAnimationStatus? status,
    double? amplitude,
    double? frequency,
    List<double>? waveformData,
    Duration? duration,
    bool? isRecording,
    bool? isPlaying,
    double? volume,
    String? errorMessage,
  }) {
    return VoiceAnimationState(
      status: status ?? this.status,
      amplitude: amplitude ?? this.amplitude,
      frequency: frequency ?? this.frequency,
      waveformData: waveformData ?? this.waveformData,
      duration: duration ?? this.duration,
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Factory constructors para estados comunes
  const VoiceAnimationState.idle()
      : status = VoiceAnimationStatus.idle,
        amplitude = 0.0,
        frequency = 1.0,
        waveformData = const [],
        duration = Duration.zero,
        isRecording = false,
        isPlaying = false,
        volume = 0.0,
        errorMessage = null;

  factory VoiceAnimationState.listening({double amplitude = 0.5}) {
    return VoiceAnimationState(
      status: VoiceAnimationStatus.listening,
      amplitude: amplitude,
      frequency: 2.0,
      isRecording: true,
    );
  }

  factory VoiceAnimationState.processing() {
    return const VoiceAnimationState(
      status: VoiceAnimationStatus.processing,
      amplitude: 0.3,
      frequency: 1.5,
    );
  }

  factory VoiceAnimationState.speaking({double amplitude = 0.7}) {
    return VoiceAnimationState(
      status: VoiceAnimationStatus.speaking,
      amplitude: amplitude,
      frequency: 1.8,
      isPlaying: true,
    );
  }

  factory VoiceAnimationState.error(String message) {
    return VoiceAnimationState(
      status: VoiceAnimationStatus.error,
      amplitude: 0.0,
      frequency: 1.0,
      errorMessage: message,
    );
  }

  // Getters de conveniencia
  bool get isIdle => status == VoiceAnimationStatus.idle;
  bool get isListening => status == VoiceAnimationStatus.listening;
  bool get isProcessing => status == VoiceAnimationStatus.processing;
  bool get isSpeaking => status == VoiceAnimationStatus.speaking;
  bool get hasError => status == VoiceAnimationStatus.error;
  bool get isActive => isListening || isProcessing || isSpeaking;
  bool get shouldAnimate => amplitude > 0.0 && isActive;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceAnimationState &&
        other.status == status &&
        other.amplitude == amplitude &&
        other.frequency == frequency &&
        other.duration == duration &&
        other.isRecording == isRecording &&
        other.isPlaying == isPlaying &&
        other.volume == volume &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        amplitude.hashCode ^
        frequency.hashCode ^
        duration.hashCode ^
        isRecording.hashCode ^
        isPlaying.hashCode ^
        volume.hashCode ^
        errorMessage.hashCode;
  }

  @override
  String toString() {
    return 'VoiceAnimationState(status: $status, amplitude: $amplitude, frequency: $frequency, duration: $duration, isRecording: $isRecording, isPlaying: $isPlaying, volume: $volume, errorMessage: $errorMessage)';
  }
}