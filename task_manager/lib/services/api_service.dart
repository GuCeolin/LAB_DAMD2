import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static const String _androidBaseUrl = 'http://10.0.2.2:3000';
  static const String _iosBaseUrl = 'http://localhost:3000';

  String get _baseUrl {
    if (kIsWeb) return _iosBaseUrl;
    if (Platform.isAndroid) return _androidBaseUrl;
    return _iosBaseUrl;
  }

  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tasks'));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Task.fromMap(item)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toMap()),
    );

    if (response.statusCode == 201) {
      return Task.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  Future<Task> updateTask(Task task) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toMap()),
    );

    if (response.statusCode == 200) {
      return Task.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete task');
    }
  }
}
