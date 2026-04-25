import 'organization.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String state;
  final DateTime startDate;
  final DateTime endDate;
  final List<OrganizationUser> users;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.state,
    required this.startDate,
    required this.endDate,
    required this.users,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final String id = (json['_id'] ?? json['id'] ?? '').toString();
    final String title = (json['title'] ?? '').toString();

    return Task(
      id: id,
      title: title,
      description: (json['description'] ?? '').toString(),
      state: (json['state'] ?? 'TO DO').toString(),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      users: (json['users'] as List<dynamic>?)
          ?.map((dynamic u) => OrganizationUser.fromJson(u))
          .toList() ??
          [],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    } else if (value is DateTime) {
      return value;
    }
    throw FormatException('Invalid date in Task: $value');
  }
}
