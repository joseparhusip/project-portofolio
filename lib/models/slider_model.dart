// lib/models/slider_model.dart

class SliderModel {
  final int sliderId;
  final String imageUrl;

  const SliderModel({
    required this.sliderId,
    required this.imageUrl,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      sliderId: int.tryParse(json['slider_id']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}
