import 'dart:convert';

class LendModel {
  final String? id;
  final String category;
  final String title;
  final String description;
  final List<String> imageUrls;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  // ✅ ADD THESE FIELDS to match Donation model
  final String donorId;      // The person requesting the item (lender becomes "donor")
  final String donorName;    // Name of the person requesting
  final String donorPhoto;   // Photo of the person requesting

  LendModel({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.availableFrom,
    this.availableUntil,
    this.locationAddress,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
    required this.donorId,     // ✅ Required
    required this.donorName,   // ✅ Required
    required this.donorPhoto,  // ✅ Required
  }) : createdAt = createdAt ?? DateTime.now();

  // Update fromJson
  factory LendModel.fromJson(Map<String, dynamic> map) {
    return LendModel(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(jsonDecode(map['imageUrls']))
          : <String>[],
      availableFrom: map['availableFrom'] != null
          ? DateTime.parse(map['availableFrom'])
          : null,
      availableUntil: map['availableUntil'] != null
          ? DateTime.parse(map['availableUntil'])
          : null,
      locationAddress: map['locationAddress'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      donorId: map['lenderId'] ?? map['donorId'] ?? '', // ✅ Use lenderId or donorId
      donorName: map['lenderName'] ?? map['donorName'] ?? 'Unknown', // ✅
      donorPhoto: map['lenderPhoto'] ?? map['donorPhoto'] ?? '', // ✅
    );
  }

  // Update toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'imageUrls': jsonEncode(imageUrls),
      'availableFrom': availableFrom?.toIso8601String(),
      'availableUntil': availableUntil?.toIso8601String(),
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'donorId': donorId,     // ✅
      'donorName': donorName, // ✅
      'donorPhoto': donorPhoto, // ✅
    };
  }
}