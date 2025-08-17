import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'live_map_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final bool isOrganizer;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.isOrganizer,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Stream<EventModel> _eventStream;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _eventStream = _firebaseService.getEventStream(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isOrganizer)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editEvent();
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Event'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Event', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: StreamBuilder<EventModel>(
        stream: _eventStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading event: ${snapshot.error}',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            );
          }

          final event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Header
                _buildEventHeader(event),
                
                const SizedBox(height: 24),
                
                // Event Details
                _buildEventDetails(event),
                
                const SizedBox(height: 24),
                
                // Organizer View
                if (widget.isOrganizer) ...[
                  _buildOrganizerView(event),
                ] else ...[
                  // Participant View
                  _buildParticipantView(event),
                ],
                
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(event),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventHeader(EventModel event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} at ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.venueAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(EventModel event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Organizer: ${event.organizerName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${event.approvedParticipants.length} approved participants',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            if (event.pendingParticipants.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.pending,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.pendingParticipants.length} pending requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerView(EventModel event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (event.pendingParticipants.isEmpty)
              Text(
                'No pending join requests',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              )
            else
              ...event.pendingParticipants.map((participantId) => 
                _buildJoinRequestItem(participantId, event.id)
              ),
            
            const SizedBox(height: 20),
            
            // Mini Map (Placeholder)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: AppTheme.textSecondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Event Location',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantView(EventModel event) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Sharing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Allow others to see my location',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Switch(
                      value: authProvider.userModel?.isLocationShared ?? false,
                      onChanged: (value) {
                        authProvider.updateLocationSharing(value);
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                if (event.approvedParticipants.isEmpty)
                  Text(
                    'No approved participants yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  )
                else
                  ...event.approvedParticipants.map((participantId) => 
                    _buildParticipantItem(participantId)
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinRequestItem(String participantId, String eventId) {
    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUser(participantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  user.name.isNotEmpty 
                      ? user.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleJoinRequest(eventId, participantId, 'approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('APPROVE'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleJoinRequest(eventId, participantId, 'rejected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.textSecondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('REJECT'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantItem(String participantId) {
    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUser(participantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  user.name.isNotEmpty 
                      ? user.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (user.isLocationShared)
                Icon(
                  Icons.location_on,
                  color: AppTheme.successColor,
                  size: 16,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(EventModel event) {
    if (widget.isOrganizer) {
      return ElevatedButton(
        onPressed: event.isRideStarted ? null : () => _startRide(event.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: event.isRideStarted 
              ? AppTheme.textSecondaryColor 
              : AppTheme.primaryColor,
        ),
        child: Text(
          event.isRideStarted ? 'RIDE STARTED' : 'START RIDE',
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveMapScreen(eventId: event.id),
            ),
          );
        },
        child: const Text('VIEW MAP'),
      );
    }
  }

  Future<void> _handleJoinRequest(String eventId, String participantId, String status) async {
    try {
      await _firebaseService.updateParticipantStatus(
        eventId: eventId,
        userId: participantId,
        status: status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _startRide(String eventId) async {
    try {
      await _firebaseService.startRide(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ride started successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting ride: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _editEvent() {
    // TODO: Navigate to edit event screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    try {
      await _firebaseService.deleteEvent(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
