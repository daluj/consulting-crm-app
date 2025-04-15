import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isConsultant => _currentUser?.isConsultant ?? false;
  String? get errorMessage => _errorMessage;

  // Initialize auth state from shared preferences
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final username = prefs.getString('username');
        if (username != null) {
          final user = await _databaseService.getUserByUsername(username);
          _currentUser = user;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login method
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get user from database
      final user = await _databaseService.getUserByUsername(username);

      // Check if user exists
      if (user == null) {
        _errorMessage = 'User not found';
        return false;
      }

      // Check if password matches
      if (user.password != password) {
        _errorMessage = 'Invalid password';
        return false;
      }

      // Set current user
      _currentUser = user;

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_consultant', user.isConsultant);
      await prefs.setString('username', user.username);
      
      if (!user.isConsultant && user.clientId != null) {
        await prefs.setInt('client_id', user.clientId!);
      }

      return true;
    } catch (e) {
      _errorMessage = 'An error occurred during login: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register method
  Future<bool> register(String username, String password, bool isConsultant, int? clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if username already exists
      final existingUser = await _databaseService.getUserByUsername(username);
      if (existingUser != null) {
        _errorMessage = 'Username already exists';
        return false;
      }

      // Create new user
      final newUser = User(
        username: username,
        password: password,
        isConsultant: isConsultant,
        clientId: clientId,
      );

      // Insert user into database
      final userId = await _databaseService.insertUser(newUser);
      if (userId <= 0) {
        _errorMessage = 'Failed to create user';
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'An error occurred during registration: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear current user
      _currentUser = null;

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('username');
      await prefs.remove('client_id');
    } catch (e) {
      _errorMessage = 'An error occurred during logout: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change password method
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      _errorMessage = 'No user is logged in';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verify current password
      if (_currentUser!.password != currentPassword) {
        _errorMessage = 'Current password is incorrect';
        return false;
      }

      // Update password
      final updatedUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password: newPassword,
        isConsultant: _currentUser!.isConsultant,
        clientId: _currentUser!.clientId,
      );

      // Update user in database
      final result = await _databaseService.updateUser(updatedUser);
      if (result <= 0) {
        _errorMessage = 'Failed to update password';
        return false;
      }

      // Update current user
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      _errorMessage = 'An error occurred while changing password: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset error message
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}