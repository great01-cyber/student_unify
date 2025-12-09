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

  // Donor = lender (person giving the item)
  final String donorId;
  final String donorName;
  final String donorPhoto;

  // Requester = person requesting to borrow the item
  // Only store ID - fetch name and photo from users collection when needed
  final String? requesterId;

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
    required this.donorId,
    required this.donorName,
    required this.donorPhoto,
    this.requesterId, // Nullable - only set when someone requests
  }) : createdAt = createdAt ?? DateTime.now();

  // FROM JSON
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
      longitude:
      map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),

      // Donor/Lender
      donorId: map['lenderId'] ?? map['donorId'] ?? '',
      donorName: map['lenderName'] ?? map['donorName'] ?? 'Unknown',
      donorPhoto: map['lenderPhoto'] ?? map['donorPhoto'] ?? '',

      // Requester - only ID
      requesterId: map['requesterId'] ?? map['RequesterId'],
    );
  }

  // TO JSON
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

      // Donor
      'donorId': donorId,
      'donorName': donorName,
      'donorPhoto': donorPhoto,

      // Requester - only ID
      'requesterId': requesterId,
    };
  }

  // Helper method to create a copy with updated fields
  LendModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    List<String>? imageUrls,
    DateTime? availableFrom,
    DateTime? availableUntil,
    String? locationAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? donorId,
    String? donorName,
    String? donorPhoto,
    String? requesterId,
  }) {
    return LendModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      donorPhoto: donorPhoto ?? this.donorPhoto,
      requesterId: requesterId ?? this.requesterId,
    );
  }

  // Check if item has been requested
  bool get hasRequester => requesterId != null && requesterId!.isNotEmpty;
}