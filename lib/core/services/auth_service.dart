import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';

/// Simple Firestore-based authentication service.
/// Stores user credentials in Firestore with SHA-256 hashed passwords.
/// Session state is persisted via SharedPreferences.
class AuthService extends ChangeNotifier {
  final String businessId;
  final bool isMockMode;

  UserAccount? _currentUser;
  bool _isLoading = true;
  bool _isAdminMode = false; // For PIN-based quick switch

  UserAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin == true || _isAdminMode;
  bool get isWorker => _currentUser?.isWorker == true && !_isAdminMode;
  bool get isAdminMode => _isAdminMode;
  String get currentUserId => _currentUser?.id ?? '';
  String get currentUserName => _currentUser?.name ?? 'Unknown';
  String get currentUserRole => isAdmin ? 'admin' : 'worker';

  AuthService({required this.businessId, this.isMockMode = false}) {
    if (isMockMode) {
      _currentUser = UserAccount(
        id: 'mock_admin',
        name: 'Mock Admin',
        email: 'admin@ledgerflow.com',
        passwordHash: '',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );
      _isLoading = false;
    } else {
      _restoreSession();
    }
  }

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  /// Hash a password with SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if any users exist (first-time setup check)
  Future<bool> hasAnyUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking users: $e');
      return false;
    }
  }

  /// Create the initial admin account (first-time setup)
  Future<bool> createAdminAccount({
    required String email,
    required String password,
    required String name,
    String? pin,
  }) async {
    try {
      final hasUsers = await hasAnyUsers();
      if (hasUsers) {
        debugPrint('Admin account already exists');
        return false;
      }

      final docRef = FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .doc();

      final user = UserAccount(
        id: docRef.id,
        email: email.toLowerCase().trim(),
        passwordHash: _hashPassword(password),
        name: name.trim(),
        role: UserRole.admin,
        pin: pin,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await docRef.set(user.toMap());
      _currentUser = user;
      await _saveSession(user.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating admin: $e');
      return false;
    }
  }

  /// Create a worker account (admin-only)
  Future<bool> createWorkerAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    if (!isAdmin) return false;

    try {
      // Check if email already exists
      final existing = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('Email already exists');
        return false;
      }

      final docRef = FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .doc();

      final user = UserAccount(
        id: docRef.id,
        email: email.toLowerCase().trim(),
        passwordHash: _hashPassword(password),
        name: name.trim(),
        role: UserRole.worker,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await docRef.set(user.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating worker: $e');
      return false;
    }
  }

  /// Login with email and password
  Future<String?> login(String email, String password) async {
    try {
      final passwordHash = _hashPassword(password);
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'No account found with this email';
      }

      final doc = snapshot.docs.first;
      final user = UserAccount.fromMap(doc.id, doc.data());

      if (!user.isActive) {
        return 'This account has been disabled. Contact your admin.';
      }

      if (user.passwordHash != passwordHash) {
        return 'Incorrect password';
      }

      // Update last login time
      await doc.reference.update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      _isAdminMode = false;
      await _saveSession(user.id);
      notifyListeners();
      return null; // null means success
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Login failed. Check your connection.';
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    _isAdminMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_id');
    notifyListeners();
  }

  /// Restore session from SharedPreferences
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('auth_user_id');

      if (userId == null || userId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final user = UserAccount.fromMap(doc.id, doc.data()!);
        if (user.isActive) {
          _currentUser = user;
        } else {
          // Account disabled, clear session
          await prefs.remove('auth_user_id');
        }
      } else {
        await prefs.remove('auth_user_id');
      }
    } catch (e) {
      debugPrint('Session restore error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_id', userId);
  }

  /// PIN-based quick switch to admin mode
  Future<bool> switchToAdminWithPin(String pin) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final admin = UserAccount.fromMap(
          snapshot.docs.first.id, snapshot.docs.first.data());

      if (admin.pin == null || admin.pin!.isEmpty) return false;
      if (admin.pin != pin) return false;

      _isAdminMode = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PIN switch error: $e');
      return false;
    }
  }

  /// Exit admin mode (back to worker)
  void exitAdminMode() {
    _isAdminMode = false;
    notifyListeners();
  }

  /// Get all user accounts (admin-only)
  Future<List<UserAccount>> getAllUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => UserAccount.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  /// Toggle worker active status (admin-only)
  Future<bool> toggleWorkerStatus(String userId, bool isActive) async {
    if (!isAdmin) return false;
    try {
      await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .doc(userId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      debugPrint('Error toggling worker status: $e');
      return false;
    }
  }

  /// Reset worker password (admin-only)
  Future<bool> resetWorkerPassword(String userId, String newPassword) async {
    if (!isAdmin) return false;
    try {
      await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .doc(userId)
          .update({'passwordHash': _hashPassword(newPassword)});
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return false;
    }
  }

  /// Update admin PIN
  Future<bool> updateAdminPin(String newPin) async {
    if (!isAdmin || _currentUser == null) return false;
    try {
      // Find the admin account
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      await snapshot.docs.first.reference.update({'pin': newPin});
      _currentUser = _currentUser!.copyWith(pin: newPin);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating PIN: $e');
      return false;
    }
  }

  /// Delete a worker account (admin-only)
  Future<bool> deleteWorker(String userId) async {
    if (!isAdmin) return false;
    try {
      await FirebaseFirestore.instance
          .collection(_getCollectionPath('users'))
          .doc(userId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting worker: $e');
      return false;
    }
  }
}
