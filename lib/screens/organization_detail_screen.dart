import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/organization.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final OrganizationService _organizationService = OrganizationService();
  late Future<Organization> _organizationFuture;
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _organizationFuture = _loadOrganization();
    _tasksFuture = _loadTasks();
  }

  Future<Organization> _loadOrganization() async {
    final String? accessToken = context.read<AuthProvider>().accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No active session. Please log in again.');
    }

    return _organizationService.getOrganizationFull(
      widget.organization.id,
      accessToken: accessToken,
    );
  }

  Future<List<Task>> _loadTasks() async {
    final String? accessToken = context.read<AuthProvider>().accessToken;

    return _organizationService.fetchTasksByOrganization(
      widget.organization.id,
      accessToken: accessToken,
    );
  }

  void _reloadTasks() {
    setState(() {
      _tasksFuture = _loadTasks();
    });
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Organization>(
      future: _organizationFuture,
      builder: (BuildContext context, AsyncSnapshot<Organization> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Organization')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Could not load organization.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final Organization organization = snapshot.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(organization.name),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(
                        Icons.business,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organization.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Task>>(
                  future: _tasksFuture,
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<Task>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Could not load tasks. ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final List<Task> tasks = snapshot.data ?? <Task>[];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming tasks',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              Chip(
                                label: Text('${tasks.length} active'),
                                backgroundColor:
                                    Colors.blueAccent.withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: tasks.isEmpty
                              ? const Center(
                                  child: Text(
                                    'There are no tasks in this organization yet',
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  itemCount: tasks.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final Task task = tasks[index];

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        onTap: () async {
                                          final bool? result =
                                              await Navigator.of(context).push<
                                                  bool>(
                                            MaterialPageRoute<bool>(
                                              builder: (context) =>
                                                  TaskDetailScreen(task: task),
                                            ),
                                          );
                                          if (result == true) {
                                            _reloadTasks();
                                          }
                                        },
                                        leading: const Icon(Icons.task_alt),
                                        title: Text(
                                          task.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Start: ${_formatDate(task.startDate)}\nEnd: ${_formatDate(task.endDate)}',
                                        ),
                                        isThreeLine: true,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildCreateButton(context, organization),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateButton(BuildContext context, Organization organization) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final bool? created = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (BuildContext context) => CreateTaskScreen(
                  organizationId: organization.id,
                  users: organization.users,
                ),
              ),
            );

            if (created == true) {
              _reloadTasks();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task),
              SizedBox(width: 10),
              Text(
                'Create task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
