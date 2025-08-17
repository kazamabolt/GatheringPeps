import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../models/event_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'createdAt': Timestamp.now(),
        'isLocationShared': false,
      });

      return userCredential;
    } catch (e) {
      developer.log('Error signing up: $e', name: 'FirebaseService.signUp');
      rethrow;
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      developer.log('Error signing in: $e', name: 'FirebaseService.signIn');
      rethrow;
    }
  }
  
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Configure Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'sign_in_canceled', message: 'Google sign in was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName ?? 'User',
          'profileImageUrl': userCredential.user!.photoURL,
          'createdAt': Timestamp.now(),
          'isLocationShared': false,
        });
      }
      
      return userCredential;
    } catch (e) {
      developer.log('Error signing in with Google: $e', name: 'FirebaseService.signInWithGoogle');
      if (e.toString().contains('network_error')) {
        throw FirebaseAuthException(code: 'network_error', message: 'Network error. Please check your internet connection.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw FirebaseAuthException(code: 'sign_in_failed', message: 'Google Sign-In failed. Please try again.');
      }
      rethrow;
    }
  }
  


  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User methods
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      developer.log('Error getting user: $e', name: 'FirebaseService.getUser');
      return null;
    }
  }

  Future<void> updateUserLocation({
    required String userId,
    required Position position,
    required bool isLocationShared,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': Timestamp.now(),
        'isLocationShared': isLocationShared,
      });
    } catch (e) {
      developer.log('Error updating user location: $e', name: 'FirebaseService.updateUserLocation');
      rethrow;
    }
  }
  
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Create a reference to the location where the file will be uploaded
      final storageRef = FirebaseStorage.instance.ref();
      final profileImageRef = storageRef.child('profile_images/$userId.jpg');
      
      // Upload the file
      await profileImageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Get download URL
      final downloadUrl = await profileImageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      developer.log('Error uploading profile image: $e', name: 'FirebaseService.uploadProfileImage');
      rethrow;
    }
  }
  
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toFirestore());
    } catch (e) {
      developer.log('Error updating user data: $e', name: 'FirebaseService.updateUserData');
      rethrow;
    }
  }

  // Event methods
  Future<String> createEvent(EventModel event) async {
    try {
      DocumentReference docRef = await _firestore.collection('events').add(
        event.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      developer.log('Error creating event: $e', name: 'FirebaseService.createEvent');
      rethrow;
    }
  }

  Future<List<EventModel>> getUserEvents(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      developer.log('Error getting user events: $e', name: 'FirebaseService.getUserEvents');
      return [];
    }
  }

  Future<List<EventModel>> getParticipatingEvents(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('events')
          .where('participantIds', arrayContains: userId)
          .orderBy('dateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      developer.log('Error getting participating events: $e', name: 'FirebaseService.getParticipatingEvents');
      return [];
    }
  }

  Future<EventModel?> getEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      developer.log('Error getting event: $e', name: 'FirebaseService.getEvent');
      return null;
    }
  }

  Future<void> joinEvent({
    required String eventId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'participantStatuses.$userId': 'pending',
      });
    } catch (e) {
      developer.log('Error joining event: $e', name: 'FirebaseService.joinEvent');
      rethrow;
    }
  }

  Future<void> updateParticipantStatus({
    required String eventId,
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'participantStatuses.$userId': status,
      });
    } catch (e) {
      developer.log('Error updating participant status: $e', name: 'FirebaseService.updateParticipantStatus');
      rethrow;
    }
  }

  Future<void> startRide(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'isRideStarted': true,
        'startRideTime': Timestamp.now(),
        'status': 'ongoing',
      });
    } catch (e) {
      developer.log('Error starting ride: $e', name: 'FirebaseService.startRide');
      rethrow;
    }
  }

  Future<void> updateEventStatus(String eventId, String status) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': status,
      });
    } catch (e) {
      developer.log('Error updating event status: $e', name: 'FirebaseService.updateEventStatus');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      developer.log('Error deleting event: $e', name: 'FirebaseService.deleteEvent');
      rethrow;
    }
  }

  Future<void> completeEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': 'completed',
      });
    } catch (e) {
      developer.log('Error completing event: $e', name: 'FirebaseService.completeEvent');
      rethrow;
    }
  }

  // Stream methods for real-time updates
  Stream<EventModel> getEventStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => EventModel.fromFirestore(doc));
  }

  Stream<List<EventModel>> getUserEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<EventModel>> getParticipatingEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('participantIds', arrayContains: userId)
        .where('status', whereIn: ['upcoming', 'ongoing'])
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<EventModel>> getCompletedEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }
}
