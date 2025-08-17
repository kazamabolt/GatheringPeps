import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isLocationShared;
  final GeoPoint? currentLocation;
  final DateTime? lastLocationUpdate;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
    this.isLocationShared = false,
    this.currentLocation,
    this.lastLocationUpdate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isLocationShared: data['isLocationShared'] ?? false,
      currentLocation: data['currentLocation'],
      lastLocationUpdate: data['lastLocationUpdate'] != null
          ? (data['lastLocationUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isLocationShared': isLocationShared,
      'currentLocation': currentLocation,
      'lastLocationUpdate': lastLocationUpdate != null
          ? Timestamp.fromDate(lastLocationUpdate!)
          : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    DateTime? createdAt,
    bool? isLocationShared,
    GeoPoint? currentLocation,
    DateTime? lastLocationUpdate,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isLocationShared: isLocationShared ?? this.isLocationShared,
      currentLocation: currentLocation ?? this.currentLocation,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
  }
}
