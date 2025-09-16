import 'package:equatable/equatable.dart';

class OnboardingStep extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final int order;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.order,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imagePath,
        order,
      ];
}