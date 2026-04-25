import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/organization.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../services/organization_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String organizationId;
  final List<OrganizationUser> users;
  final Task? taskToEdit;

  const CreateTaskScreen({
    super.key,
    required this.organizationId,
    required this.users,
    this.taskToEdit,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OrganizationService _organizationService = OrganizationService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  late Set<String> _selectedUserIds;
  String _selectedStatus = 'TO DO';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select start date',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _startDateController.text = _formatDate(_startDate!);

      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = null;
        _endDateController.clear();
      }
    });

    _formKey.currentState?.validate();
  }

  Future<void> _pickEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _endDate ?? _startDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate ?? DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select end date',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _endDateController.text = _formatDate(_endDate!);
    });

    _formKey.currentState?.validate();
  }

  DateTime _normalizeStartDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 8, 0, 0);
  }

  DateTime _normalizeEndDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 17, 0, 0);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one user')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String? token = context.read<AuthProvider>().accessToken;

      if (widget.taskToEdit != null) {
        await _organizationService.editTask(
          taskId: widget.taskToEdit!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          state: _selectedStatus,
          startDate: _normalizeStartDate(_startDate!),
          endDate: _normalizeEndDate(_endDate!),
          users: _selectedUserIds.toList(),
          accessToken: token,
        );
      } else {
        await _organizationService.createTask(
          organizationId: widget.organizationId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          state: _selectedStatus,
          startDate: _normalizeStartDate(_startDate!),
          endDate: _normalizeEndDate(_endDate!),
          users: _selectedUserIds.toList(),
          accessToken: token,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openUserSelector() async {
    if (widget.users.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Select users',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.users.length,
                        itemBuilder: (BuildContext context, int index) {
                          final OrganizationUser user = widget.users[index];
                          return CheckboxListTile(
                            value: _selectedUserIds.contains(user.id),
                            onChanged: (bool? checked) {
                              setModalState(() {
                                if (checked == true) {
                                  _selectedUserIds.add(user.id);
                                } else {
                                  _selectedUserIds.remove(user.id);
                                }
                              });
                              setState(() {});
                            },
                            title: Text(user.name),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit != null ? 'Edit Task' : 'New Task'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            label: 'Title',
                            hint: 'Enter task title',
                            icon: Icons.title,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration(
                            label: 'Description',
                            hint: 'Enter task description',
                            icon: Icons.description,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: _buildInputDecoration(
                            label: 'Status',
                            hint: 'Select status',
                            icon: Icons.info_outline,
                          ),
                          items: ['TO DO', 'IN PROGRESS', 'DONE']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: _pickStartDate,
                          decoration: _buildInputDecoration(
                            label: 'Start Date',
                            hint: 'Select a date',
                            icon: Icons.event,
                          ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                          validator: (value) => _startDate == null ? 'Start date is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          onTap: _pickEndDate,
                          decoration: _buildInputDecoration(
                            label: 'End Date',
                            hint: 'Select a date',
                            icon: Icons.event_available,
                          ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                          validator: (value) {
                            if (_endDate == null) return 'End date is required';
                            if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                              return 'End date cannot be before start date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: _openUserSelector,
                          child: InputDecorator(
                            decoration: _buildInputDecoration(
                              label: 'Assigned users',
                              hint: 'Select users',
                              icon: Icons.group,
                            ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                            child: Text(
                              _selectedUserIds.isEmpty
                                  ? 'Tap to select'
                                  : widget.users
                                      .where((u) => _selectedUserIds.contains(u.id))
                                      .map((u) => u.name)
                                      .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.taskToEdit != null ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
