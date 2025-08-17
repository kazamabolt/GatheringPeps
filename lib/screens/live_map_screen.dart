import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class LiveMapScreen extends StatefulWidget {
  final String eventId;

  const LiveMapScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<EventModel> _eventStream;

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
        title: const Text('Live Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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

          return Column(
            children: [
              // Map Container
              Expanded(
                child: _buildMapContainer(event),
              ),
              
              // Action Button
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _startRide(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'START RIDE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapContainer(EventModel event) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Placeholder for Google Maps
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.backgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Live Map View',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Event: ${event.title}',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationPins(),
                  ],
                ),
              ),
            ),
            
            // Map Controls Overlay
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        // TODO: Implement current location
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () {
                        // TODO: Implement zoom in
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () {
                        // TODO: Implement zoom out
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Event Info Overlay
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Location',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.venueAddress,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
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

  Widget _buildLocationPins() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Location Pins',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPinLegend(
                color: AppTheme.primaryColor,
                label: 'Event Venue',
              ),
              _buildPinLegend(
                color: AppTheme.successColor,
                label: 'Participants',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinLegend({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _startRide() {
    // TODO: Implement ride start functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ride started! Updating Firestore...'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

// TODO: Implement actual Google Maps integration
// This would include:
// 1. Google Maps Flutter widget
// 2. Custom markers for event venue and participants
// 3. Real-time location updates
// 4. Map controls and interactions
// 5. Route planning and navigation
