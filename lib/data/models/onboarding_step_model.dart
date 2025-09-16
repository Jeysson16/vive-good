import 'package:hive/hive.dart';
import '../../domain/entities/onboarding_step.dart';

part 'onboarding_step_model.g.dart';

@HiveType(typeId: 1)
class OnboardingStepModel extends OnboardingStep {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String imagePath;
  
  @HiveField(4)
  final int order;

  const OnboardingStepModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.order,
  }) : super(
         id: id,
         title: title,
         description: description,
         imagePath: imagePath,
         order: order,
       );

  factory OnboardingStepModel.fromJson(Map<String, dynamic> json) {
    return OnboardingStepModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imagePath: json['imagePath'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'order': order,
    };
  }

  OnboardingStep toEntity() {
    return OnboardingStep(
      id: id,
      title: title,
      description: description,
      imagePath: imagePath,
      order: order,
    );
  }
}
