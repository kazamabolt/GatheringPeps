import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../utils/app_theme.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  GeoPoint? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Name Field
                _buildTextField(
                  controller: _titleController,
                  label: 'Event Name',
                  icon: Icons.event,
                  hint: 'Enter event name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter event name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Date & Time Field
                _buildDateTimeField(),
                
                const SizedBox(height: 20),
                
                // Venue Field
                _buildTextField(
                  controller: _venueController,
                  label: 'Venue',
                  icon: Icons.location_on,
                  hint: 'Enter venue address',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter venue address';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Location Picker (Placeholder for Google Maps)
                _buildLocationPicker(),
                
                const SizedBox(height: 20),
                
                // Description Field
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  hint: 'Enter event description',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter event description';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Save Button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Widget _buildDateTimeField() {
    return InkWell(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy - h:mm a').format(_selectedDateTime),
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Location on Map',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
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
                    'Google Maps Integration',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select location',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSave,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('SAVE'),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // For now, we'll use a default location since Google Maps isn't fully integrated
    if (_selectedLocation == null) {
      _selectedLocation = const GeoPoint(37.7749, -122.4194); // Default to San Francisco
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();

      final event = EventModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: _selectedDateTime,
        venue: _selectedLocation!,
        venueAddress: _venueController.text.trim(),
        organizerId: authProvider.currentUser!.uid,
        organizerName: authProvider.userModel?.name ?? 'Unknown',
        participantIds: [],
        participantStatuses: {},
        createdAt: DateTime.now(),
      );

      await firebaseService.createEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
