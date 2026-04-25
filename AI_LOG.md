## Gemini Code Assist

description: (json['description'] ?? '').toString(),
state: (json['state'] ?? 'TO DO').toString(),
startDate: _parseDate(json['startDate']),
endDate: _parseDate(json['endDate']),

factory User.fromJson(Map<String, dynamic> json) {
Organization? org;
if (json['organization'] != null) {
if (json['organization'] is Map<String, dynamic>) {
org = Organization.fromJson(json['organization']);
} else {
// If it's just a String (ID), create an Organization with that ID
org = Organization(
id: json['organization'].toString(),
name: 'Organization', // Fallback name
users: [],
);
}
}

role: json['role'] ?? 'user',
organization: org,

String? _accessToken;
String? get accessToken => _accessToken;

// Response shape: { message, accessToken, usuario: { _id, name, email, role, organization } }
final Map<String, dynamic> response =
await _authService.login(email.trim(), password.trim());

      _accessToken = response['accessToken'] as String?;

      final dynamic rawUser = response['usuario'];
      if (rawUser == null || rawUser is! Map<String, dynamic>) {
        throw Exception('Unexpected server response');
      }

      _currentUser = User.fromJson(rawUser);

Future<bool> signup(
String name,
String email,
String password,
String organizationId,
) async {
_isLoading = true;
_errorMessage = '';
notifyListeners();

    try {
      // Response shape: { user: populatedUser, accessToken }
      final Map<String, dynamic> response = await _authService.signup(
        name,
        email.trim(),
        password.trim(),
        organizationId,
      );

      _accessToken = response['accessToken'] as String?;

      final dynamic rawUser = response['user'];
      if (rawUser == null || rawUser is! Map<String, dynamic>) {
        throw Exception('Unexpected server response');
      }

      _currentUser = User.fromJson(rawUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
}

Future<void> loadProfileFromApi() async {
if (_currentUser == null || _accessToken == null || _accessToken!.isEmpty) {
return;
}

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> rawUser = await _authService.fetchUserById(
        _currentUser!.id,
        _accessToken!,
      );

      _currentUser = User.fromJson(rawUser);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
}

this.taskToEdit,

final TextEditingController _descriptionController = TextEditingController();

late Set<String> _selectedUserIds;
String _selectedStatus = 'TO DO';

    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _startDate = widget.taskToEdit!.startDate;
      _endDate = widget.taskToEdit!.endDate;
      _startDateController.text = _formatDate(_startDate!);
      _endDateController.text = _formatDate(_endDate!);
      _selectedUserIds = widget.taskToEdit!.users.map((u) => u.id).toSet();
      _selectedStatus = widget.taskToEdit!.state;
    } else {
      _selectedUserIds = widget.users.map((OrganizationUser user) => user.id).toSet();
    }

Color _getStatusColor(String state) {
switch (state) {
case 'DONE':
return Colors.green;
case 'IN PROGRESS':
return Colors.orange;
case 'TO DO':
default:
return Colors.blueGrey;
}
}

Future<void> _deleteTask() async {
final bool? confirm = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
title: const Text('Delete Task'),
content: const Text('Are you sure you want to delete this task?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Cancel'),
),
TextButton(
onPressed: () => Navigator.pop(context, true),
style: TextButton.styleFrom(foregroundColor: Colors.red),
child: const Text('Delete'),
),
],
),
);

    if (confirm == true) {
      try {
        final token = context.read<AuthProvider>().accessToken;
        await _organizationService.deleteTask(_currentTask.id, accessToken: token);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting task: $e')),
          );
        }
      }
    }
}

Future<void> _editTask() async {
final bool? updated = await Navigator.of(context).push<bool>(
MaterialPageRoute(
builder: (context) => CreateTaskScreen(
organizationId: '', // Not needed for editing, but required by constructor
users: _currentTask.users, // Pass current assigned users
taskToEdit: _currentTask,
),
),
);

    if (updated == true) {
      // If the task was updated, we need to refresh the details.
      // For simplicity, we'll just pop and let the previous screen reload tasks.
      // A more robust solution might involve fetching the updated task from the API.
      if (mounted) {
        Navigator.pop(context, true); // Indicate that a change occurred
      }
    }
}

                    const Row(
                        children: [
                          Icon(Icons.assignment, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            'Task',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_currentTask.state).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentTask.state,
                          style: TextStyle(
                            color: _getStatusColor(_currentTask.state),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.titulo,
                    _currentTask.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
@@ -72,17 +193,36 @@ class TaskDetailScreen extends StatelessWidget {
),
const SizedBox(height: 8),
Text(
'ID: ${task.id}',
'ID: ${_currentTask.id}',
style: TextStyle(color: Colors.grey[500], fontSize: 12),
),
if (_currentTask.description.isNotEmpty) ...[
const SizedBox(height: 16),
const Text(
'Description',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: Colors.black54,
),
),
const SizedBox(height: 4),
Text(
_currentTask.description,
style: const TextStyle(
fontSize: 16,
color: Colors.black87,
),
),
],
],
),
),

      throw Exception('Error connecting to the server: $e');
    }
}

Future<Map<String, dynamic>> fetchUserById(String userId, String accessToken) async {
try {
final response = await http.get(
Uri.parse('${AppConstants.baseUrl}/users/$userId'),
headers: <String, String>{
'Content-Type': 'application/json',
'Authorization': 'Bearer $accessToken',
},
);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Error getting user');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }

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
final response = await http.get(Uri.parse('${AppConstants.baseUrl}/organizaciones'));
final response = await http.get(
Uri.parse('${AppConstants.baseUrl}/organizations'),
headers: _buildHeaders(accessToken: accessToken),
);

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((json) => Organization.fromJson(json)).toList();
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
        throw Exception('Error al conectar con el backend: ${response.statusCode}');
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

      throw Exception('No se pudo conectar al backend. ¿Está corriendo en el puerto 1337? Error: $e');
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

##

##