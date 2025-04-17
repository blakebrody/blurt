import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class StorageService {
  // Keys
  static const String userKey = 'user_data';
  
  // Save user data to local storage
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      // Create a deep copy and ensure all values are serializable
      final Map<String, dynamic> serializableData = {};
      userData.forEach((key, value) {
        if (value == null || 
            value is String || 
            value is num || 
            value is bool) {
          serializableData[key] = value;
        } else {
          // Convert non-primitive types to string
          serializableData[key] = value.toString();
        }
      });
      
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(serializableData);
      return await prefs.setString(userKey, userDataJson);
    } catch (e) {
      Logger.error('Error saving user data', e);
      return false;
    }
  }
  
  // Get user data from local storage
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(userKey);
      
      if (userDataJson == null) {
        return null;
      }
      
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Error getting user data', e);
      return null;
    }
  }
  
  // Clear user data (for logout)
  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(userKey);
    } catch (e) {
      Logger.error('Error clearing user data', e);
      return false;
    }
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final userData = await getUserData();
      return userData != null;
    } catch (e) {
      Logger.error('Error checking login status', e);
      return false;
    }
  }
  
  // Generic methods for storing and retrieving different types of data
  
  // Save a string value
  static Future<bool> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      print('Error saving string value for key $key: $e');
      return false;
    }
  }
  
  // Get a string value
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('Error getting string value for key $key: $e');
      return null;
    }
  }
  
  // Save a boolean value
  static Future<bool> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      print('Error saving boolean value for key $key: $e');
      return false;
    }
  }
  
  // Get a boolean value
  static Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      print('Error getting boolean value for key $key: $e');
      return null;
    }
  }
  
  // Save an integer value
  static Future<bool> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(key, value);
    } catch (e) {
      print('Error saving integer value for key $key: $e');
      return false;
    }
  }
  
  // Get an integer value
  static Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      print('Error getting integer value for key $key: $e');
      return null;
    }
  }
  
  // Remove a specific value
  static Future<bool> removeValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      print('Error removing value for key $key: $e');
      return false;
    }
  }
  
  // Check if a key exists
  static Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      print('Error checking if key $key exists: $e');
      return false;
    }
  }
  
  // Clear all data (complete reset)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }
} 