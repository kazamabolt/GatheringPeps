import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

import 'package:geolocator/geolocator.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _currentUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseService.authStateChanges.listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _userModel = await _firebaseService.getUser(userId);
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _firebaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _firebaseService.signIn(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }
  
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _firebaseService.signInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }
  


  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> updateLocationSharing(bool isLocationShared) async {
    if (_currentUser == null || _userModel == null) return;
    
    try {
      await _firebaseService.updateUserLocation(
        userId: _currentUser!.uid,
        position: _userModel!.currentLocation != null 
          ? Position(
              latitude: _userModel!.currentLocation!.latitude,
              longitude: _userModel!.currentLocation!.longitude,
              timestamp: _userModel!.lastLocationUpdate ?? DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            )
          : Position(
              latitude: 0,
              longitude: 0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            ),
        isLocationShared: isLocationShared,
      );
      
      _userModel = _userModel!.copyWith(isLocationShared: isLocationShared);
      notifyListeners();
    } catch (e) {
      print('Error updating location sharing: $e');
    }
  }

  void updateUserModel(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  void clearError() {
    _clearError();
  }
}
