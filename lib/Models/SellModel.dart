import 'dart:convert';

class SellModel {
  final String? id; // optional: database id or firestore doc id
  final String category;
  final String title;
  final String description;
  final double price; // 🎯 Mandatory price for selling
  final List<String> imageUrls; // either local file paths or uploaded URLs
  final String? instructions; // e.g., "Cash only" or "Pickup by 5pm"
  final String? locationAddress; // human readable
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  SellModel({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.price, // 🎯 Required in constructor
    this.imageUrls = const [],
    this.instructions,
    this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SellModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    double? price, // 🎯 Updated field
    List<String>? imageUrls,
    String? instructions,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return SellModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price, // 🎯 Copied mandatory field
      imageUrls: imageUrls ?? this.imageUrls,
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
      'price': price, // 🎯 Mapped price
      // store list as json string
      'imageUrls': jsonEncode(imageUrls),
      'instructions': instructions,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SellModel.fromMap(Map<String, dynamic> map) {
    return SellModel(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Ensure price is safely parsed to double
      price: map['price'] != null ? (map['price'] as num).toDouble() : 0.0, // 🎯 Parsed price
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(jsonDecode(map['imageUrls']) as List<dynamic>)
          : <String>[],
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

  // For Firestore / REST (Using toMap() for data conversion)
  Map<String, dynamic> toJson() => toMap();

  // Factory constructor for easy use with Firestore/API data
  factory SellModel.fromJson(Map<String, dynamic> json) =>
      SellModel.fromMap(json);

  @override
  String toString() {
    return 'SellModel(id: $id, category: $category, title: $title, '
        'price: £${price.toStringAsFixed(2)}, location: $locationAddress)';
  }
}