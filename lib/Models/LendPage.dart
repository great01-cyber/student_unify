import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ✅ NEW: Two-sided confirmation fields
  final String? receiverId;
  final bool donorConfirmed;
  final DateTime? donorConfirmedDate;
  final bool receiverConfirmed;
  final DateTime? receiverConfirmedDate;

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
    // ✅ NEW: Confirmation parameters
    this.receiverId,
    this.donorConfirmed = false,
    this.donorConfirmedDate,
    this.receiverConfirmed = false,
    this.receiverConfirmedDate,
  }) : createdAt = createdAt ?? DateTime.now();

  // FROM JSON
  factory LendModel.fromJson(Map<String, dynamic> map) {
    return LendModel(
      id: map['id']?.toString(),
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrls: map['imageUrls'] != null
          ? (map['imageUrls'] is String
          ? List<String>.from(jsonDecode(map['imageUrls']))
          : List<String>.from(map['imageUrls']))
          : <String>[],

      // Handle Timestamp for availableFrom
      availableFrom: map['availableFrom'] == null
          ? null
          : (map['availableFrom'] is Timestamp
          ? (map['availableFrom'] as Timestamp).toDate()
          : DateTime.parse(map['availableFrom'])),

      // Handle Timestamp for availableUntil
      availableUntil: map['availableUntil'] == null
          ? null
          : (map['availableUntil'] is Timestamp
          ? (map['availableUntil'] as Timestamp).toDate()
          : DateTime.parse(map['availableUntil'])),

      locationAddress: map['locationAddress'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,

      // Handle Timestamp for createdAt
      createdAt: map['createdAt'] == null
          ? DateTime.now()
          : (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'])),

      // Donor/Lender
      donorId: map['lenderId'] ?? map['donorId'] ?? '',
      donorName: map['lenderName'] ?? map['donorName'] ?? 'Unknown',
      donorPhoto: map['lenderPhoto'] ?? map['donorPhoto'] ?? '',

      // Requester - only ID
      requesterId: map['requesterId'] ?? map['RequesterId'],

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

      // Donor / Lender (write both to be safe)
      'lenderId': donorId,
      'lenderName': donorName,
      'lenderPhoto': donorPhoto,

      'donorId': donorId,
      'donorName': donorName,
      'donorPhoto': donorPhoto,

      // Requester - only ID
      'requesterId': requesterId,

      // ✅ NEW: Confirmation fields
      'receiverId': receiverId,
      'donorConfirmed': donorConfirmed,
      'donorConfirmedDate': donorConfirmedDate?.toIso8601String(),
      'receiverConfirmed': receiverConfirmed,
      'receiverConfirmedDate': receiverConfirmedDate?.toIso8601String(),
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
    // ✅ NEW: Confirmation parameters
    String? receiverId,
    bool? donorConfirmed,
    DateTime? donorConfirmedDate,
    bool? receiverConfirmed,
    DateTime? receiverConfirmedDate,
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
      // ✅ NEW
      receiverId: receiverId ?? this.receiverId,
      donorConfirmed: donorConfirmed ?? this.donorConfirmed,
      donorConfirmedDate: donorConfirmedDate ?? this.donorConfirmedDate,
      receiverConfirmed: receiverConfirmed ?? this.receiverConfirmed,
      receiverConfirmedDate: receiverConfirmedDate ?? this.receiverConfirmedDate,
    );
  }

  // Check if item has been requested
  bool get hasRequester => requesterId != null && requesterId!.isNotEmpty;

  // ✅ NEW: Check if both parties have confirmed
  bool get isBothConfirmed => donorConfirmed && receiverConfirmed;

  // ✅ NEW: Check if transfer is pending (at least one confirmed)
  bool get isTransferPending => (donorConfirmed || receiverConfirmed) && !isBothConfirmed;
}