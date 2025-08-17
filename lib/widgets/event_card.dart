import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../utils/app_theme.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  _buildStatusChip(event.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Event Details
              _buildEventDetail(
                icon: Icons.calendar_today,
                text: DateFormat('MMM dd, h:mm a').format(event.dateTime),
              ),
              
              const SizedBox(height: 8),
              
              _buildEventDetail(
                icon: Icons.location_on,
                text: event.venueAddress,
              ),
              
              const SizedBox(height: 8),
              
              _buildEventDetail(
                icon: Icons.person,
                text: '${event.participantIds.length} participants',
              ),
              
              const SizedBox(height: 16),
              
              // Organizer Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      event.organizerName.isNotEmpty 
                          ? event.organizerName[0].toUpperCase()
                          : 'O',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Organized by ${event.organizerName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetail({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(EventStatus status) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case EventStatus.upcoming:
        chipColor = AppTheme.primaryColor;
        statusText = 'Upcoming';
        break;
      case EventStatus.ongoing:
        chipColor = AppTheme.successColor;
        statusText = 'Ongoing';
        break;
      case EventStatus.completed:
        chipColor = AppTheme.textSecondaryColor;
        statusText = 'Completed';
        break;
      case EventStatus.cancelled:
        chipColor = AppTheme.errorColor;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
