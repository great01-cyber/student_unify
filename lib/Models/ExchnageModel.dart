
import 'dart:convert';

class ExchangeModel {
  final String? id; // optional: database id or firestore doc id
  final String category;
  final String title;
  final String description;
  final String exchangeRequest; // 🎯 REQUIRED: Description of what the user wants in exchange
  final String? desiredCategory; // Optional: Category of item desired
  final List<String> imageUrls; // either local file paths or uploaded URLs
  final String? instructions; // e.g., "Must be collected this week"
  final String? locationAddress; // human readable
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  ExchangeModel({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.exchangeRequest, // 🎯 Required in constructor
    this.desiredCategory,
    this.imageUrls = const [],
    this.instructions,
    this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ExchangeModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    String? exchangeRequest, // 🎯 Updated field
    String? desiredCategory,
    List<String>? imageUrls,
    String? instructions,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return ExchangeModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      exchangeRequest: exchangeRequest ?? this.exchangeRequest, // 🎯 Copied mandatory field
      desiredCategory: desiredCategory ?? this.desiredCategory,
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
      'exchangeRequest': exchangeRequest, // 🎯 Mapped request
      'desiredCategory': desiredCategory,
      // store list as json string
      'imageUrls': jsonEncode(imageUrls),
      'instructions': instructions,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExchangeModel.fromMap(Map<String, dynamic> map) {
    return ExchangeModel(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      exchangeRequest: map['exchangeRequest'] ?? '', // 🎯 Parsed mandatory field
      desiredCategory: map['desiredCategory'],
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
  factory ExchangeModel.fromJson(Map<String, dynamic> json) =>
      ExchangeModel.fromMap(json);

  @override
  String toString() {
    return 'ExchangeModel(id: $id, category: $category, title: $title, '
        'request: $exchangeRequest, location: $locationAddress)';
  }
}