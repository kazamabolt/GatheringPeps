import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}

enum ParticipantStatus {
  pending,
  approved,
  rejected,
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final GeoPoint venue;
  final String venueAddress;
  final String organizerId;
  final String organizerName;
  final List<String> participantIds;
  final Map<String, ParticipantStatus> participantStatuses;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime? startRideTime;
  final bool isRideStarted;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.venue,
    required this.venueAddress,
    required this.organizerId,
    required this.organizerName,
    required this.participantIds,
    required this.participantStatuses,
    this.status = EventStatus.upcoming,
    required this.createdAt,
    this.startRideTime,
    this.isRideStarted = false,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Map<String, ParticipantStatus> statuses = {};
    if (data['participantStatuses'] != null) {
      Map<String, dynamic> rawStatuses = data['participantStatuses'];
      rawStatuses.forEach((key, value) {
        statuses[key] = ParticipantStatus.values.firstWhere(
          (e) => e.toString() == 'ParticipantStatus.$value',
          orElse: () => ParticipantStatus.pending,
        );
      });
    }

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      venue: data['venue'],
      venueAddress: data['venueAddress'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantStatuses: statuses,
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${data['status']}',
        orElse: () => EventStatus.upcoming,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startRideTime: data['startRideTime'] != null
          ? (data['startRideTime'] as Timestamp).toDate()
          : null,
      isRideStarted: data['isRideStarted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, String> statuses = {};
    participantStatuses.forEach((key, value) {
      statuses[key] = value.toString().split('.').last;
    });

    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'venue': venue,
      'venueAddress': venueAddress,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'participantIds': participantIds,
      'participantStatuses': statuses,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'startRideTime': startRideTime != null
          ? Timestamp.fromDate(startRideTime!)
          : null,
      'isRideStarted': isRideStarted,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    GeoPoint? venue,
    String? venueAddress,
    String? organizerId,
    String? organizerName,
    List<String>? participantIds,
    Map<String, ParticipantStatus>? participantStatuses,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? startRideTime,
    bool? isRideStarted,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      participantIds: participantIds ?? this.participantIds,
      participantStatuses: participantStatuses ?? this.participantStatuses,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startRideTime: startRideTime ?? this.startRideTime,
      isRideStarted: isRideStarted ?? this.isRideStarted,
    );
  }

  List<String> get approvedParticipants {
    List<String> approved = [];
    participantStatuses.forEach((id, status) {
      if (status == ParticipantStatus.approved) {
        approved.add(id);
      }
    });
    return approved;
  }

  List<String> get pendingParticipants {
    List<String> pending = [];
    participantStatuses.forEach((id, status) {
      if (status == ParticipantStatus.pending) {
        pending.add(id);
      }
    });
    return pending;
  }
}
