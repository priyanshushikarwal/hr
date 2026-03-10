import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/inputs.dart';
import '../../../../core/services/export_service.dart';
import '../../../../shared/layouts/main_layout.dart';
import '../../../../shared/layouts/header.dart';
import '../../data/models/employee_model.dart';
import '../../domain/providers/employee_providers.dart';
import '../widgets/add_employee_drawer.dart';
import '../widgets/employee_filters.dart';
import '../widgets/employee_documents_dialog.dart';

/// Employee Master Screen - Table view with all employees
class EmployeeMasterScreen extends ConsumerStatefulWidget {
  const EmployeeMasterScreen({super.key});

  @override
  ConsumerState<EmployeeMasterScreen> createState() =>
      _EmployeeMasterScreenState();
}

class _EmployeeMasterScreenState extends ConsumerState<EmployeeMasterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterDepartment;
  String? _filterEmployeeType;
  String? _filterStatus;
  Set<String> _selectedIds = {};
  bool _showFilters = false;
  bool _showAddDrawer = false;

  List<Employee> _getFilteredEmployees(List<Employee> employees) {
    var filtered = employees;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.fullName.toLowerCase().contains(query) ||
            e.employeeCode.toLowerCase().contains(query) ||
            e.email.toLowerCase().contains(query) ||
            e.department.toLowerCase().contains(query) ||
            e.designation.toLowerCase().contains(query);
      }).toList();
    }

    // Apply filters
    if (_filterDepartment != null) {
      filtered = filtered
          .where((e) => e.department == _filterDepartment)
          .toList();
    }
    if (_filterEmployeeType != null) {
      filtered = filtered
          .where((e) => e.employeeType == _filterEmployeeType)
          .toList();
    }
    if (_filterStatus != null) {
      filtered = filtered.where((e) => e.status == _filterStatus).toList();
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _filterDepartment = null;
      _filterEmployeeType = null;
      _filterStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeListProvider);
    final totalEmployees = employeeState.employees.length;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              PageHeader(
                title: 'Employee Master',
                subtitle: '$totalEmployees employees in your organization',
                breadcrumbs: const ['Home', 'Employee Master'],
                actions: [
                  SecondaryButton(
                    text: 'Export',
                    icon: AppIcons.export,
                    onPressed: () async {
                      final employees = ref
                          .read(employeeListProvider)
                          .employees;
                      if (employees.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No employees to export'),
                          ),
                        );
                        return;
                      }
                      try {
                        final path = await ExportService.instance
                            .exportEmployees(
                              employees.map((e) => e.toJson()).toList(),
                            );
                        if (path != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exported to: $path')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(
                    text: 'Add Employee',
                    icon: AppIcons.userAdd,
                    onPressed: () {
                      setState(() => _showAddDrawer = true);
                    },
                  ),
                ],
              ),

              // Stats Cards
              _buildStatsRow(),

              const SizedBox(height: AppSpacing.lg),

              // Table Card
              ContentCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Table Header with Search & Filters
                    _buildTableHeader(),

                    // Filters Panel
                    AnimatedContainer(
                      duration: AppSpacing.durationFast,
                      height: _showFilters ? null : 0,
                      child: _showFilters
                          ? EmployeeFilters(
                              selectedDepartment: _filterDepartment,
                              selectedEmployeeType: _filterEmployeeType,
                              selectedStatus: _filterStatus,
                              onDepartmentChanged: (v) =>
                                  setState(() => _filterDepartment = v),
                              onEmployeeTypeChanged: (v) =>
                                  setState(() => _filterEmployeeType = v),
                              onStatusChanged: (v) =>
                                  setState(() => _filterStatus = v),
                              onClearFilters: _clearFilters,
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Data Table
                    SizedBox(height: 500, child: _buildDataTable()),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Add Employee Drawer
        if (_showAddDrawer)
          AddEmployeeDrawer(
            onClose: () => setState(() => _showAddDrawer = false),
            onSave: (employee, password) async {
              setState(() => _showAddDrawer = false);
              try {
                await ref
                    .read(employeeListProvider.notifier)
                    .createEmployee(employee, password: password);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Employee saved successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save employee: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final employeeState = ref.watch(employeeListProvider);
    final employees = employeeState.employees;

    final total = employees.length;
    final officeCount = employees.where((e) => e.isOffice).length;
    final factoryCount = employees.where((e) => e.isFactory).length;
    final activeCount = employees.where((e) => e.isActive).length;
    final inactiveCount = employees.where((e) => !e.isActive).length;

    return Row(
      children: [
        _MiniStatCard(
          label: 'Total Employees',
          value: total.toString(),
          icon: AppIcons.employees,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        _MiniStatCard(
          label: 'Office',
          value: officeCount.toString(),
          icon: AppIcons.office,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.md),
        _MiniStatCard(
          label: 'Factory',
          value: factoryCount.toString(),
          icon: AppIcons.factory,
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.md),
        _MiniStatCard(
          label: 'Active',
          value: activeCount.toString(),
          icon: AppIcons.active,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.md),
        _MiniStatCard(
          label: 'Inactive',
          value: inactiveCount.toString(),
          icon: AppIcons.inactive,
          color: AppColors.textTertiary,
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search by name, ID, email, department...',
              width: double.infinity,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Filter Toggle
          _FilterToggleButton(
            isActive: _showFilters,
            filterCount: [
              _filterDepartment,
              _filterEmployeeType,
              _filterStatus,
            ].where((f) => f != null).length,
            onTap: () => setState(() => _showFilters = !_showFilters),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Column Settings
          AppIconButton(
            icon: AppIcons.settings,
            tooltip: 'Column Settings',
            onPressed: () {},
          ),

          // Selected Actions
          if (_selectedIds.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} selected',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GhostButton(
                    text: 'Export',
                    icon: AppIcons.export,
                    color: AppColors.primary,
                    onPressed: () async {
                      final allEmployees = ref
                          .read(employeeListProvider)
                          .employees;
                      final selected = allEmployees
                          .where((e) => _selectedIds.contains(e.id))
                          .toList();
                      if (selected.isEmpty) return;
                      try {
                        final path = await ExportService.instance
                            .exportEmployees(
                              selected.map((e) => e.toJson()).toList(),
                            );
                        if (path != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Exported ${selected.length} employees to: $path',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  GhostButton(
                    text: 'Delete',
                    icon: AppIcons.delete,
                    color: AppColors.error,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                            'Are you sure you want to delete ${_selectedIds.length} employee(s)? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                for (String id in _selectedIds) {
                                  await ref
                                      .read(employeeListProvider.notifier)
                                      .deleteEmployee(id);
                                }
                                setState(() {
                                  _selectedIds.clear();
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Employees deleted successfully',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final employeeState = ref.watch(employeeListProvider);
    final employees = _getFilteredEmployees(employeeState.employees);

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.employees, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No employees found',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your search or filters',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 1000,
      headingRowColor: WidgetStateProperty.all(AppColors.backgroundSecondary),
      headingTextStyle: AppTypography.tableHeader,
      dataTextStyle: AppTypography.tableCell,
      headingRowHeight: 48,
      dataRowHeight: 64,
      dividerThickness: 1,
      showCheckboxColumn: true,
      onSelectAll: (selected) {
        setState(() {
          if (selected == true) {
            _selectedIds = employees.map((e) => e.id).toSet();
          } else {
            _selectedIds = {};
          }
        });
      },
      columns: const [
        DataColumn2(label: Text('EMPLOYEE'), size: ColumnSize.L),
        DataColumn2(label: Text('ID'), size: ColumnSize.S),
        DataColumn2(label: Text('DEPARTMENT'), size: ColumnSize.M),
        DataColumn2(label: Text('DESIGNATION'), size: ColumnSize.M),
        DataColumn2(label: Text('TYPE'), size: ColumnSize.S),
        DataColumn2(label: Text('STATUS'), size: ColumnSize.S),
        DataColumn2(label: Text('JOINED'), size: ColumnSize.S),
        DataColumn2(label: Text(''), size: ColumnSize.S, fixedWidth: 80),
      ],
      rows: employees.map((employee) {
        final isSelected = _selectedIds.contains(employee.id);

        return DataRow2(
          selected: isSelected,
          onSelectChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedIds.add(employee.id);
              } else {
                _selectedIds.remove(employee.id);
              }
            });
          },
          onTap: () {
            // TODO: Navigate to employee details
          },
          cells: [
            // Employee Name & Email
            DataCell(
              Row(
                children: [
                  UserAvatar(name: employee.fullName, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          employee.fullName,
                          style: AppTypography.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          employee.email,
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Employee Code
            DataCell(
              Text(
                employee.employeeCode,
                style: AppTypography.tableCell.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Department
            DataCell(Text(employee.department)),
            // Designation
            DataCell(Text(employee.designation)),
            // Type
            DataCell(
              EmployeeTypeBadge(type: employee.employeeType, isSmall: true),
            ),
            // Status
            DataCell(
              StatusBadge(
                label: employee.status.toUpperCase(),
                type: employee.isActive
                    ? StatusType.success
                    : StatusType.neutral,
                isSmall: true,
              ),
            ),
            // Joining Date
            DataCell(
              Text(
                _formatDate(employee.joiningDate),
                style: AppTypography.tableCell,
              ),
            ),
            // Actions
            DataCell(
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppIconButton(
                    icon: AppIcons.view,
                    tooltip: 'View Details',
                    size: 32,
                    iconSize: 16,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) =>
                            EmployeeDocumentsDialog(employee: employee),
                      );
                    },
                  ),
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: 'Edit',
                    size: 32,
                    iconSize: 16,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    ).animate().fadeIn();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.titleLarge),
                Text(label, style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterToggleButton extends StatefulWidget {
  final bool isActive;
  final int filterCount;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.isActive,
    required this.filterCount,
    required this.onTap,
  });

  @override
  State<_FilterToggleButton> createState() => _FilterToggleButtonState();
}

class _FilterToggleButtonState extends State<_FilterToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive || _isHovered
                ? AppColors.primarySurface
                : AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isActive ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.filter,
                size: 18,
                color: widget.isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: AppTypography.labelMedium.copyWith(
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (widget.filterCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.filterCount.toString(),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
