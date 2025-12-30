import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String? id;
  final String donorId;
  final String category;
  final String title;
  final String description;
  final double? price;
  final double? kg;
  final List<String> imageUrls;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? instructions;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  final String donorPhoto;
  final String donorName;

  final String ownerId;
  final String ownerName;

  // ✅ NEW: Two-sided confirmation fields
  final String? receiverId;
  final bool donorConfirmed;
  final DateTime? donorConfirmedDate;
  final bool receiverConfirmed;
  final DateTime? receiverConfirmedDate;

  Donation({
    this.id,
    required this.donorId,
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
    required this.ownerId,
    required this.ownerName,
    required this.donorName,
    required this.donorPhoto,
    // ✅ NEW: Confirmation parameters
    this.receiverId,
    this.donorConfirmed = false,
    this.donorConfirmedDate,
    this.receiverConfirmed = false,
    this.receiverConfirmedDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Donation copyWith({
    String? id,
    String? donorId,
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
    String? ownerId,
    String? ownerName,
    String? donorName,
    String? donorPhoto,
    // ✅ NEW: Confirmation parameters
    String? receiverId,
    bool? donorConfirmed,
    DateTime? donorConfirmedDate,
    bool? receiverConfirmed,
    DateTime? receiverConfirmedDate,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
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
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      donorName: donorName ?? this.donorName,
      donorPhoto: donorPhoto ?? this.donorPhoto,
      // ✅ NEW
      receiverId: receiverId ?? this.receiverId,
      donorConfirmed: donorConfirmed ?? this.donorConfirmed,
      donorConfirmedDate: donorConfirmedDate ?? this.donorConfirmedDate,
      receiverConfirmed: receiverConfirmed ?? this.receiverConfirmed,
      receiverConfirmedDate: receiverConfirmedDate ?? this.receiverConfirmedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'kg': kg,
      'imageUrls': imageUrls,
      'availableFrom': availableFrom,
      'availableUntil': availableUntil,
      'instructions': instructions,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'donorName': donorName,
      'donorPhoto': donorPhoto,
      // ✅ NEW
      'receiverId': receiverId,
      'donorConfirmed': donorConfirmed,
      'donorConfirmedDate': donorConfirmedDate,
      'receiverConfirmed': receiverConfirmed,
      'receiverConfirmedDate': receiverConfirmedDate,
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id']?.toString(),
      donorId: map['donorId'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',

      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      kg: map['kg'] != null ? (map['kg'] as num).toDouble() : null,

      imageUrls: map['imageUrls'] is String
          ? List<String>.from(jsonDecode(map['imageUrls']))
          : List<String>.from(map['imageUrls'] ?? []),

      // -------------------------------
      // FIXED TIMESTAMP SUPPORT
      // -------------------------------
      availableFrom: map['availableFrom'] == null
          ? null
          : (map['availableFrom'] is Timestamp
          ? (map['availableFrom'] as Timestamp).toDate()
          : DateTime.parse(map['availableFrom'])),

      availableUntil: map['availableUntil'] == null
          ? null
          : (map['availableUntil'] is Timestamp
          ? (map['availableUntil'] as Timestamp).toDate()
          : DateTime.parse(map['availableUntil'])),

      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'])),

      instructions: map['instructions'],
      locationAddress: map['locationAddress'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,

      ownerId: map['ownerId'] ?? "",
      ownerName: map['ownerName'] ?? "Unknown",

      donorName: map['donorName'] ?? "Unknown Donor",
      donorPhoto: map['donorPhoto'] ?? "",

      // ✅ NEW: Confirmation fields
      receiverId: map['receiverId'],
      donorConfirmed: map['donorConfirmed'] ?? false,
      donorConfirmedDate: map['donorConfirmedDate'] == null
          ? null
          : (map['donorConfirmedDate'] is Timestamp
          ? (map['donorConfirmedDate'] as Timestamp).toDate()
          : DateTime.parse(map['donorConfirmedDate'])),
      receiverConfirmed: map['receiverConfirmed'] ?? false,
      receiverConfirmedDate: map['receiverConfirmedDate'] == null
          ? null
          : (map['receiverConfirmedDate'] is Timestamp
          ? (map['receiverConfirmedDate'] as Timestamp).toDate()
          : DateTime.parse(map['receiverConfirmedDate'])),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Donation.fromJson(Map<String, dynamic> json) => Donation.fromMap(json);
}