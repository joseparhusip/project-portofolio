// lib/models/product_review_model.dart

class ProductReview {
  final int reviewId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String username;
  final String userImageUrl;

  ProductReview({
    required this.reviewId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.username,
    required this.userImageUrl,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      reviewId: int.tryParse(json['review_id'].toString()) ?? 0,
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      username: json['username'] ?? 'User Anonim',
      userImageUrl: json['user_image_url'] ?? '',
    );
  }
}
