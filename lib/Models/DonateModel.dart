// donation_model.dart
import 'dart:convert';

class Donation {
  final String? id; // optional: database id or firestore doc id
  final String category;
  final String title;
  final String description;
  final double? price; // nullable if free
  final double? kg; // weight estimate
  final List<String> imageUrls; // either local file paths or uploaded URLs
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? instructions;
  final String? locationAddress; // human readable
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Donation({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.price,
    this.kg,
    this.imageUrls = const [],
    this.availableFrom,
    this.availableUntil,
    this.instructions,
    this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Donation copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    double? price,
    double? kg,
    List<String>? imageUrls,
    DateTime? availableFrom,
    DateTime? availableUntil,
    String? instructions,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return Donation(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      kg: kg ?? this.kg,
      imageUrls: imageUrls ?? this.imageUrls,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      instructions: instructions ?? this.instructions,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Map for sqflite/local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'kg': kg,
      // store list as json string
      'imageUrls': jsonEncode(imageUrls),
      'availableFrom': availableFrom?.toIso8601String(),
      'availableUntil': availableUntil?.toIso8601String(),
      'instructions': instructions,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      kg: map['kg'] != null ? (map['kg'] as num).toDouble() : null,
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(jsonDecode(map['imageUrls']) as List<dynamic>)
          : <String>[],
      availableFrom: map['availableFrom'] != null
          ? DateTime.parse(map['availableFrom'])
          : null,
      availableUntil: map['availableUntil'] != null
          ? DateTime.parse(map['availableUntil'])
          : null,
      instructions: map['instructions'],
      locationAddress: map['locationAddress'],
      latitude:
      map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude:
      map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // For Firestore / REST
  Map<String, dynamic> toJson() => toMap();

  factory Donation.fromJson(Map<String, dynamic> json) =>
      Donation.fromMap(json);

  @override
  String toString() {
    return 'Donation(id: $id, category: $category, title: $title, '
        'images: ${imageUrls.length}, location: $locationAddress)';
  }
}
