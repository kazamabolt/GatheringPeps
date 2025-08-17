import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isImageUploading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Validate file size (max 5MB)
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            _showErrorSnackBar('Image size must be less than 5MB');
          }
          return;
        }

        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image: ${e.toString()}');
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showDiscardChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  bool get _hasChanges {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return false;
    return _nameController.text.trim() != user.name || _imageFile != null;
  }

  Future<void> _saveProfile() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nameValidation = _validateName(_nameController.text);
    if (nameValidation != null) {
      setState(() {
        _nameError = nameValidation;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _nameError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      final currentUser = authProvider.userModel;

      if (currentUser == null) {
        throw Exception('User session expired. Please login again.');
      }

      // Upload image if selected
      String? profileImageUrl = currentUser.profileImageUrl;
      if (_imageFile != null) {
        setState(() {
          _isImageUploading = true;
        });
        
        try {
          profileImageUrl = await firebaseService.uploadProfileImage(_imageFile!, currentUser.id);
        } catch (e) {
          throw Exception('Failed to upload image: ${e.toString()}');
        } finally {
          setState(() {
            _isImageUploading = false;
          });
        }
      }

      // Update user data
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        profileImageUrl: profileImageUrl,
      );

      await firebaseService.updateUserData(updatedUser);
      authProvider.updateUserModel(updatedUser);

      // Clear the selected image after successful upload
      setState(() {
        _imageFile = null;
      });

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date != null) {
      // Handle Firestore Timestamp
      try {
        dateTime = date.toDate();
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Unknown';
    }
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  Future<void> _showDeleteAccountDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Delete Account'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement account deletion
                _showErrorSnackBar('Account deletion is not yet implemented');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldPop = await _showDiscardChangesDialog();
          return shouldPop;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.userModel;
            if (user == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading user data...'),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileSection(user),
                        const SizedBox(height: 24),
                        _buildPersonalInfoSection(user),
                        const SizedBox(height: 24),
                        _buildAccountInfoSection(user),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                        const SizedBox(height: 16),
                        _buildDeleteAccountSection(),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Updating profile...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isLoading ? null : _showImageSourceDialog,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                              ? NetworkImage(user.profileImageUrl!)
                              : null) as ImageProvider?,
                      child: _imageFile == null && (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                  ),
                  if (_isImageUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _imageFile != null ? Icons.check : Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.name.isNotEmpty ? user.name : 'No Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user.email.isNotEmpty ? user.email : 'No Email',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'New image selected',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              focusNode: _focusNode,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                LengthLimitingTextInputFormatter(50),
              ],
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: _focusNode.hasFocus ? AppTheme.primaryColor : Colors.grey,
                ),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _isLoading ? null : () {
                          _nameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                errorText: _nameError,
                counterText: '${_nameController.text.length}/50',
              ),
              validator: _validateName,
              onChanged: (value) {
                setState(() {
                  _nameError = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              'Email',
              user.email.isNotEmpty ? user.email : 'Not provided',
              Icons.email_outlined,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'User ID',
              user.id,
              Icons.fingerprint,
              copyable: true,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Account Created',
              _formatDate(user.createdAt),
              Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool copyable = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]!,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 18,
              color: Colors.grey[600]!,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              _showSuccessSnackBar('Copied to clipboard');
            },
            tooltip: 'Copy to clipboard',
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final hasChanges = _hasChanges;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !hasChanges) ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasChanges ? AppTheme.primaryColor : Colors.grey[300],
          foregroundColor: hasChanges ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: hasChanges ? 2 : 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasChanges ? Colors.white : Colors.grey[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isImageUploading ? 'Uploading Image...' : 'Saving Changes...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasChanges ? Icons.save : Icons.check_circle_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasChanges ? 'Save Changes' : 'No Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeleteAccountSection() {
    return Card(
      elevation: 1,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Once you delete your account, there is no going back. Please be certain.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _showDeleteAccountDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}