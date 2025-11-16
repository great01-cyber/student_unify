import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore types if needed (though not strictly required for the core model structure)

class LendModel {
  final String? id; // optional: database id or firestore doc id
  final String category;
  final String title;
  final String description;
  final String? shortNote; // 🎯 New field for lending
  final String? extraInformation; // 🎯 New field for lending
  final List<String> imageUrls; // either local file paths or uploaded URLs
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? instructions;
  final String? locationAddress; // human readable
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  LendModel({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.shortNote, // 🎯 Included new field
    this.extraInformation, // 🎯 Included new field
    this.imageUrls = const [],
    this.availableFrom,
    this.availableUntil,
    this.instructions,
    this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  LendModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    String? shortNote, // 🎯 Updated field
    String? extraInformation, // 🎯 Updated field
    List<String>? imageUrls,
    DateTime? availableFrom,
    DateTime? availableUntil,
    String? instructions,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return LendModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      shortNote: shortNote ?? this.shortNote, // 🎯 Copied new field
      extraInformation: extraInformation ?? this.extraInformation, // 🎯 Copied new field
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
      'shortNote': shortNote, // 🎯 Mapped new field
      'extraInformation': extraInformation, // 🎯 Mapped new field
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

  factory LendModel.fromMap(Map<String, dynamic> map) {
    return LendModel(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      shortNote: map['shortNote'], // 🎯 Parsed new field
      extraInformation: map['extraInformation'], // 🎯 Parsed new field
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

  factory LendModel.fromJson(Map<String, dynamic> json) =>
      LendModel.fromMap(json);

  @override
  String toString() {
    return 'LendModel(id: $id, category: $category, title: $title, '
        'note: $shortNote, images: ${imageUrls.length}, location: $locationAddress)';
  }
}