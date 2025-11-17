import 'dart:convert';

class BorrowModel {
  final String? id; // optional: database id or firestore doc id
  final String category;
  final String title; // What the user wants to borrow
  final String description; // Details about the specific item requested
  final String? reason; // Why the item is needed (e.g., for a class project)
  final List<String> imageUrls; // Optional: Images showing examples of what they need
  final DateTime neededFrom; // 🎯 Required: When the item is needed
  final DateTime neededUntil; // 🎯 Required: When the item will be returned
  final String locationAddress; // Where the borrower is located for pickup/dropoff
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  BorrowModel({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.reason,
    this.imageUrls = const [],
    required this.neededFrom, // 🎯 Required field
    required this.neededUntil, // 🎯 Required field
    required this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BorrowModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    String? reason,
    List<String>? imageUrls,
    DateTime? neededFrom,
    DateTime? neededUntil,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return BorrowModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      imageUrls: imageUrls ?? this.imageUrls,
      neededFrom: neededFrom ?? this.neededFrom,
      neededUntil: neededUntil ?? this.neededUntil,
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
      'reason': reason,
      // store list as json string
      'imageUrls': jsonEncode(imageUrls),
      'neededFrom': neededFrom.toIso8601String(),
      'neededUntil': neededUntil.toIso8601String(),
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BorrowModel.fromMap(Map<String, dynamic> map) {
    return BorrowModel(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      reason: map['reason'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(jsonDecode(map['imageUrls']) as List<dynamic>)
          : <String>[],
      // Dates are required, so safe parsing is critical
      neededFrom: map['neededFrom'] != null
          ? DateTime.parse(map['neededFrom'])
          : DateTime.now(), // Fallback if data is missing
      neededUntil: map['neededUntil'] != null
          ? DateTime.parse(map['neededUntil'])
          : DateTime.now().add(const Duration(days: 7)), // Fallback
      locationAddress: map['locationAddress'] ?? '',
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
  factory BorrowModel.fromJson(Map<String, dynamic> json) =>
      BorrowModel.fromMap(json);

  @override
  String toString() {
    return 'BorrowModel(id: $id, category: $category, title: $title, '
        'needed: ${neededFrom.day}/${neededFrom.month}-${neededUntil.day}/${neededUntil.month}, location: $locationAddress)';
  }
}