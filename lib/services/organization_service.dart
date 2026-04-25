import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/organization.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class OrganizationService {
  Map<String, String> _buildHeaders({String? accessToken}) {
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  // Fetch organizations from backend
  Future<List<Organization>> getOrganizations({String? accessToken}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/organizations'),
        headers: _buildHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody is List<dynamic>) {
          return decodedBody
              .map((dynamic item) => Organization.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        if (decodedBody is Map<String, dynamic> &&
            decodedBody['organizations'] is List<dynamic>) {
          final List<dynamic> organizations = decodedBody['organizations'] as List<dynamic>;
          return organizations
              .map((dynamic item) => Organization.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        throw Exception('Invalid organization response format');
      } else {
        throw Exception(
          'Backend connection error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception(
        'Could not connect to backend. Is it running on port 1337? Error: $e',
      );
    }
  }

  Future<Organization> getOrganizationFull(
      String organizationId, {
        String? accessToken,
      }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/organizations/$organizationId/full'),
        headers: _buildHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody is Map<String, dynamic>) {
          return Organization.fromJson(decodedBody);
        }

        throw Exception('Invalid organization response format');
      } else {
        throw Exception(
          'Error getting full organization: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception(
        'Could not load full organization. Error: $e',
      );
    }
  }

  Future<List<Task>> fetchTasksByOrganization(
      String organizationId, {
        String? accessToken,
      }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/organizations/$organizationId/tasks'),
        headers: _buildHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody is List<dynamic>) {
          return decodedBody
              .map((dynamic jsonItem) => Task.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
        }

        if (decodedBody is Map<String, dynamic> &&
            decodedBody['tasks'] is List<dynamic>) {
          final List<dynamic> tasks = decodedBody['tasks'] as List<dynamic>;
          return tasks
              .map((dynamic jsonItem) => Task.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
        }

        throw Exception('Invalid tasks response format');
      }

      throw Exception('Error getting tasks: ${response.statusCode}');
    } catch (e) {
      throw Exception(
        'Could not load tasks for this organization. Error: $e',
      );
    }
  }

  Future<Task> getTaskById(String taskId, {String? accessToken}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/tasks/$taskId'),
        headers: _buildHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      }
      throw Exception('Error getting task: ${response.statusCode}');
    } catch (e) {
      throw Exception('Could not get task. Error: $e');
    }
  }

  Future<void> createTask({
    required String organizationId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> users,
    String? description,
    String? state,
    String? accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/tasks'),
        headers: _buildHeaders(accessToken: accessToken),
        body: json.encode(<String, dynamic>{
          'organizationId': organizationId,
          'title': title,
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
          'users': users,
          'description': description ?? '',
          'state': state ?? 'TO DO',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw Exception(
        'Error creating task: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Could not create task. Error: $e');
    }
  }

  Future<void> editTask({
    required String taskId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> users,
    String? description,
    String? state,
    String? accessToken,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/tasks/$taskId'),
        headers: _buildHeaders(accessToken: accessToken),
        body: json.encode(<String, dynamic>{
          'title': title,
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
          'users': users,
          'description': description ?? '',
          'state': state ?? 'TO DO',
        }),
      );

      if (response.statusCode == 200) {
        return;
      }

      throw Exception(
        'Error editing task: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Could not edit task. Error: $e');
    }
  }

  Future<void> updateTaskState(String taskId, String newState, {String? accessToken}) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/tasks/$taskId/state'),
        headers: _buildHeaders(accessToken: accessToken),
        body: json.encode(<String, dynamic>{
          'state': newState,
        }),
      );

      if (response.statusCode == 200) {
        return;
      }

      throw Exception(
        'Error updating task state: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Could not update task state. Error: $e');
    }
  }

  Future<void> deleteTask(String taskId, {String? accessToken}) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/tasks/$taskId'),
        headers: _buildHeaders(accessToken: accessToken),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      throw Exception(
        'Error deleting task: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Could not delete task. Error: $e');
    }
  }
}
