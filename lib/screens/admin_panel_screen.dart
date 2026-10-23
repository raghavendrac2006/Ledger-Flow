import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/services/auth_service.dart';
import '../core/services/audit_service.dart';
import '../core/models/user_account.dart';
import '../core/models/audit_log.dart';
import '../core/app_state.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (!auth.isAdmin) {
      return const Center(
        child: Text("Access Denied — Admin Only",
            style: TextStyle(color: AppTheme.error, fontSize: 18)),
      );
    }

    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.onSurfaceVariant,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3.0,
            labelStyle: AppTheme.labelBold.copyWith(fontSize: 11),
            unselectedLabelStyle: AppTheme.labelSm.copyWith(fontSize: 11),
            tabs: const [
              Tab(icon: Icon(Icons.people, size: 20), text: "WORKERS"),
              Tab(icon: Icon(Icons.history, size: 20), text: "AUDIT LOG"),
              Tab(icon: Icon(Icons.bar_chart, size: 20), text: "ACTIVITY"),
              Tab(icon: Icon(Icons.settings, size: 20), text: "TOOLS"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _WorkerManagementTab(),
              _AuditLogTab(),
              _WorkerActivityTab(),
              _AdminToolsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// TAB 1: Worker Management
// ──────────────────────────────────────────────────────────
class _WorkerManagementTab extends StatefulWidget {
  const _WorkerManagementTab();

  @override
  State<_WorkerManagementTab> createState() => _WorkerManagementTabState();
}

class _WorkerManagementTabState extends State<_WorkerManagementTab> {
  List<UserAccount> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final users = await auth.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _loading = false;
      });
    }
  }

  void _showAddWorkerDialog() {
    final emailC = TextEditingController();
    final passwordC = TextEditingController();
    final nameC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text("Add Worker",
            style: AppTheme.headlineMd.copyWith(color: Colors.white)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameC, "Worker Name", Icons.person_outline, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                }),
                const SizedBox(height: 12),
                _dialogField(emailC, "Email", Icons.email_outlined, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                }),
                const SizedBox(height: 12),
                _dialogField(passwordC, "Password", Icons.lock_outline,
                    obscure: true, validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 4) return 'Min 4 chars';
                  return null;
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: AppTheme.labelBold.copyWith(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = Provider.of<AuthService>(ctx, listen: false);
              final audit = Provider.of<AuditService>(ctx, listen: false);
              final success = await auth.createWorkerAccount(
                email: emailC.text.trim(),
                password: passwordC.text,
                name: nameC.text.trim(),
              );
              if (success) {
                await audit.log(
                  action: 'worker_created',
                  details: 'Created worker: ${nameC.text.trim()} (${emailC.text.trim()})',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadUsers();
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Email already exists or error occurred")),
                  );
                }
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(UserAccount user) {
    final passwordC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text("Reset Password",
            style: AppTheme.headlineMd.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Reset password for ${user.name}",
                style: AppTheme.bodyMd.copyWith(color: Colors.white70)),
            const SizedBox(height: 16),
            _dialogField(passwordC, "New Password", Icons.lock_outline, obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: AppTheme.labelBold.copyWith(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (passwordC.text.length < 4) return;
              final auth = Provider.of<AuthService>(ctx, listen: false);
              final audit = Provider.of<AuditService>(ctx, listen: false);
              final ok = await auth.resetWorkerPassword(user.id, passwordC.text);
              if (ok) {
                await audit.log(
                  action: 'worker_password_reset',
                  details: 'Reset password for ${user.name}',
                  targetType: 'user',
                  targetId: user.id,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String label, IconData icon,
      {bool obscure = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      validator: validator,
      style: AppTheme.bodyMd.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.labelSm.copyWith(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWorkerDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("ADD WORKER"),
      ),
      body: _users.isEmpty
          ? Center(
              child: Text("No users found",
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.outlineVariant),
                    boxShadow: AppTheme.hardShadowLight,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          user.isAdmin ? AppTheme.primary : AppTheme.secondary,
                      child: Icon(
                        user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(user.name, style: AppTheme.labelBold),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.isAdmin ? "ADMIN" : "WORKER",
                            style: AppTheme.labelSm.copyWith(
                              color: user.isAdmin ? AppTheme.primary : AppTheme.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!user.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "DISABLED",
                              style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(user.email,
                          style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant)),
                    ),
                    trailing: user.isAdmin
                        ? null
                        : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                            color: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            onSelected: (action) async {
                              final auth = Provider.of<AuthService>(context, listen: false);
                              final audit = Provider.of<AuditService>(context, listen: false);
                              switch (action) {
                                case 'toggle':
                                  await auth.toggleWorkerStatus(user.id, !user.isActive);
                                  await audit.log(
                                    action: user.isActive ? 'worker_disabled' : 'worker_enabled',
                                    details:
                                        '${user.isActive ? "Disabled" : "Enabled"} worker: ${user.name}',
                                    targetType: 'user',
                                    targetId: user.id,
                                  );
                                  _loadUsers();
                                  break;
                                case 'reset_password':
                                  _showResetPasswordDialog(user);
                                  break;
                                case 'delete':
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E293B),
                                      title: Text("Delete Worker?",
                                          style: AppTheme.headlineMd.copyWith(color: Colors.white)),
                                      content: Text(
                                          "Permanently delete ${user.name}'s account?",
                                          style: AppTheme.bodyMd.copyWith(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.error),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text("Delete",
                                              style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await auth.deleteWorker(user.id);
                                    await audit.log(
                                      action: 'worker_deleted',
                                      details: 'Deleted worker: ${user.name}',
                                      targetType: 'user',
                                      targetId: user.id,
                                    );
                                    _loadUsers();
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      user.isActive
                                          ? Icons.block
                                          : Icons.check_circle,
                                      color: user.isActive
                                          ? Colors.orangeAccent
                                          : Colors.greenAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      user.isActive ? "Disable" : "Enable",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reset_password',
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_reset, color: Colors.white70, size: 18),
                                    SizedBox(width: 8),
                                    Text("Reset Password",
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text("Delete",
                                        style: TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// TAB 2: Audit Log
// ──────────────────────────────────────────────────────────
class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<AuditLog> _logs = [];
  bool _loading = true;
  String _filter = 'all'; // 'all', 'destructive', 'additions'

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() async {
    setState(() => _loading = true);
    final audit = Provider.of<AuditService>(context, listen: false);
    final logs = await audit.getRecentLogs(limit: 100);
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  List<AuditLog> get _filteredLogs {
    if (_filter == 'destructive') {
      return _logs.where((l) =>
          l.action.contains('delete') ||
          l.action.contains('wipe') ||
          l.action.contains('reset')).toList();
    }
    if (_filter == 'additions') {
      return _logs.where((l) =>
          l.action.contains('add') ||
          l.action.contains('create')).toList();
    }
    return _logs;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip("All", 'all'),
              const SizedBox(width: 8),
              _buildFilterChip("Destructive", 'destructive'),
              const SizedBox(width: 8),
              _buildFilterChip("Additions", 'additions'),
              const Spacer(),
              IconButton(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh, color: AppTheme.primary),
              ),
            ],
          ),
        ),

        Expanded(
          child: _filteredLogs.isEmpty
              ? Center(
                  child: Text("No audit logs found",
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    final isDestructive = log.action.contains('delete') ||
                        log.action.contains('wipe');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: isDestructive
                              ? AppTheme.error.withValues(alpha: 0.2)
                              : AppTheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.actionIcon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: log.userRole == 'admin'
                                            ? AppTheme.primary.withValues(alpha: 0.1)
                                            : AppTheme.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        log.userName,
                                        style: AppTheme.labelSm.copyWith(
                                          color: log.userRole == 'admin'
                                              ? AppTheme.primary
                                              : AppTheme.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      log.actionLabel,
                                      style: AppTheme.labelBold.copyWith(
                                        color: isDestructive
                                            ? AppTheme.error
                                            : AppTheme.onSurface,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log.details,
                                  style: AppTheme.labelSm.copyWith(
                                      color: AppTheme.onSurfaceVariant, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(log.timestamp),
                                  style: AppTheme.labelSm.copyWith(
                                      color: AppTheme.outline, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelSm.copyWith(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// TAB 3: Worker Activity Dashboard
// ──────────────────────────────────────────────────────────
class _WorkerActivityTab extends StatefulWidget {
  const _WorkerActivityTab();

  @override
  State<_WorkerActivityTab> createState() => _WorkerActivityTabState();
}

class _WorkerActivityTabState extends State<_WorkerActivityTab> {
  Map<String, Map<String, int>> _activitySummary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  void _loadActivity() async {
    final audit = Provider.of<AuditService>(context, listen: false);
    final summary = await audit.getWorkerActivitySummary();
    if (mounted) {
      setState(() {
        _activitySummary = summary;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_activitySummary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            Text("No activity today",
                style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S WORKER ACTIVITY",
            style: AppTheme.labelBold.copyWith(
              color: AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
            style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ..._activitySummary.entries.map((workerEntry) {
            final workerName = workerEntry.key;
            final actions = workerEntry.value;
            final totalActions = actions.values.fold<int>(0, (a, b) => a + b);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.outlineVariant),
                boxShadow: AppTheme.hardShadowLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusMd),
                        topRight: Radius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            workerName.isNotEmpty ? workerName[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(workerName, style: AppTheme.labelBold),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$totalActions actions",
                            style: AppTheme.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...actions.entries.map((actionEntry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(actionEntry.key,
                              style: AppTheme.labelSm
                                  .copyWith(color: AppTheme.onSurfaceVariant)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "×${actionEntry.value}",
                              style: AppTheme.dataTabular.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// TAB 4: Admin Tools (Data Management, PIN, Settings)
// ──────────────────────────────────────────────────────────
class _AdminToolsTab extends StatelessWidget {
  const _AdminToolsTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ADMIN TOOLS",
            style: AppTheme.labelBold.copyWith(
              color: AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // PIN Management
          _ToolCard(
            icon: Icons.pin,
            title: "Quick-Switch PIN",
            subtitle: auth.currentUser?.pin != null
                ? "PIN is set (****)"
                : "No PIN configured",
            actionLabel: "SET PIN",
            onAction: () => _showSetPinDialog(context),
          ),
          const SizedBox(height: 12),

          // Delete by date range
          _ToolCard(
            icon: Icons.date_range,
            title: "Delete Data by Date Range",
            subtitle: "Remove all transactions in a date range",
            actionLabel: "SELECT DATES",
            isDestructive: true,
            onAction: () => _showDateRangeDeleteDialog(context),
          ),
          const SizedBox(height: 12),

          // Wipe all data
          _ToolCard(
            icon: Icons.delete_forever,
            title: "Wipe All Data",
            subtitle: "Reset balances and transaction logs to zero. Master lists are kept!",
            actionLabel: "WIPE ALL",
            isDestructive: true,
            onAction: () => _showWipeConfirmDialog(context),
          ),
          const SizedBox(height: 12),

          // Restore Master Data
          _ToolCard(
            icon: Icons.restore_page,
            title: "Restore Master Customers & Expenses",
            subtitle: "Verify & restore all 28 master customers and 24 expense items",
            actionLabel: "RESTORE",
            onAction: () async {
              final state = Provider.of<LedgerState>(context, listen: false);
              final audit = Provider.of<AuditService>(context, listen: false);
              await state.restoreMasterCustomersAndExpenses(context);
              await audit.log(
                action: 'master_data_restored',
                details: 'Restored master customers and expense suggestion items',
              );
            },
          ),
          const SizedBox(height: 12),

          // Backup
          _ToolCard(
            icon: Icons.cloud_download,
            title: "Backup Data",
            subtitle: "Export all data as a backup file",
            actionLabel: "BACKUP NOW",
            onAction: () {
              final state = Provider.of<LedgerState>(context, listen: false);
              state.exportBackupData(context);
            },
          ),
          const SizedBox(height: 12),

          // Logout
          _ToolCard(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out of your account",
            actionLabel: "LOGOUT",
            isDestructive: true,
            onAction: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  static void _showSetPinDialog(BuildContext context) {
    final pinC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text("Set Quick-Switch PIN",
            style: AppTheme.headlineMd.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Workers can enter this 4-digit PIN to temporarily unlock admin features on their device.",
              style: AppTheme.labelSm.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: pinC,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: AppTheme.headlineMd.copyWith(
                  color: Colors.white, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: AppTheme.labelBold.copyWith(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (pinC.text.length != 4) return;
              final auth = Provider.of<AuthService>(ctx, listen: false);
              final audit = Provider.of<AuditService>(ctx, listen: false);
              await auth.updateAdminPin(pinC.text);
              await audit.log(
                action: 'settings_changed',
                details: 'Updated admin quick-switch PIN',
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save PIN"),
          ),
        ],
      ),
    );
  }

  static void _showDateRangeDeleteDialog(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );

    if (range == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Confirm Date Range Deletion",
            style: AppTheme.headlineMd.copyWith(color: Colors.white)),
        content: Text(
          "Delete ALL transactions from ${DateFormat('dd MMM yyyy').format(range.start)} to ${DateFormat('dd MMM yyyy').format(range.end)}?\n\nThis cannot be undone!",
          style: AppTheme.bodyMd.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final state = Provider.of<LedgerState>(context, listen: false);
      final audit = Provider.of<AuditService>(context, listen: false);
      await state.deleteDataByDateRange(range.start, range.end);
      await audit.log(
        action: 'data_deleted_range',
        details:
            'Deleted data from ${DateFormat('dd MMM yyyy').format(range.start)} to ${DateFormat('dd MMM yyyy').format(range.end)}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data in selected range deleted")),
        );
      }
    }
  }

  static void _showWipeConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("⚠️ RESET ALL TRANSACTIONS TO ZERO?",
            style: AppTheme.headlineMd.copyWith(color: AppTheme.error)),
        content: Text(
          "This will reset all customer outstanding balances to ₹0, and clear all delivery logs, expenses, and flour data.\n\nNOTE: Your master customer profiles and expense items list will NEVER be deleted.",
          style: AppTheme.bodyMd.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("RESET TO ZERO",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final state = Provider.of<LedgerState>(context, listen: false);
      final audit = Provider.of<AuditService>(context, listen: false);
      await state.clearAllDataToZero();
      await audit.log(
        action: 'data_wiped',
        details: 'Complete data wipe performed by admin',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All data wiped to zero")),
        );
      }
    }
  }

  static void _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Logout?",
            style: AppTheme.headlineMd.copyWith(color: Colors.white)),
        content: Text("Are you sure you want to sign out?",
            style: AppTheme.bodyMd.copyWith(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final audit = Provider.of<AuditService>(context, listen: false);
      await audit.log(
        action: 'logout',
        details: '${auth.currentUserName} logged out',
      );
      await auth.logout();
    }
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool isDestructive;
  final VoidCallback onAction;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.isDestructive = false,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDestructive
              ? AppTheme.error.withValues(alpha: 0.2)
              : AppTheme.outlineVariant,
        ),
        boxShadow: AppTheme.hardShadowLight,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppTheme.error.withValues(alpha: 0.1)
                  : AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppTheme.error : AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.labelBold.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTheme.labelSm.copyWith(
                        color: AppTheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? AppTheme.error : AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              actionLabel,
              style: AppTheme.labelBold.copyWith(
                color: isDestructive ? AppTheme.error : AppTheme.primary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
