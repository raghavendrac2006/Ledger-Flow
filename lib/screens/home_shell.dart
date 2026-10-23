import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/models/models.dart';
import '../core/services/update_service.dart';
import 'setup_screen.dart';
import 'sales_entry_screen.dart';
import 'expenses_screen.dart';
import 'client_list_screen.dart';
import 'summary_screen.dart';
import 'owner_finance_screen.dart';
import 'ai_analyst_screen.dart';
import 'history_screen.dart';
import 'admin_panel_screen.dart';
import '../core/services/auth_service.dart';
import '../core/services/audit_service.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  String? _shownRecommendationDate;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _screens = [
      SetupScreen(onRoundsStarted: navigateToSales),
      const SalesEntryScreen(),
      const ExpensesScreen(),
      const ClientListScreen(),
      const SummaryScreen(),
      const OwnerFinanceScreen(),
      const AIAnalystScreen(),
      const HistoryScreen(),
      const AdminPanelScreen(),
    ];
    _requestNotificationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(uri);
        });
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'ledgerflow' && uri.host == 'action') {
      final type = uri.queryParameters['type'];
      final item = uri.queryParameters['item'];
      final amount = uri.queryParameters['amount'];
      
      final state = Provider.of<LedgerState>(context, listen: false);
      
      if (type == 'sale') {
        if (amount != null) {
          if (amount == '200') state.quickStartRounds("₹200 Quick Sale");
          if (amount == '500') state.quickStartRounds("₹500 Quick Sale");
        } else if (item != null && item != 'custom' && item != 'select_customer') {
          String actualItem = "";
          if (item == '1_rs_chakli') actualItem = "1 ₹ Chakli";
          if (item == '5_rs_chakli') actualItem = "₹5 Chakli";
          if (actualItem.isNotEmpty) {
            state.quickStartRounds(actualItem);
          }
        }
        setState(() {
          _currentIndex = 1; // Sales Entry
        });
      } else if (type == 'expense') {
        setState(() {
          _currentIndex = 2; // Expenses
        });
      } else if (type == 'clients') {
        setState(() {
          _currentIndex = 3; // Client List
        });
      } else if (type == 'summary') {
        setState(() {
          _currentIndex = 4; // Summary
        });
      }
    }
  }

  void _requestNotificationPermission() async {
    if (kIsWeb) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Allow Setup screen to transition to Sales screen automatically
  void navigateToSales() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final pendingRec = state.pendingRecommendation;
    if (pendingRec != null && _shownRecommendationDate != pendingRec.date) {
      _shownRecommendationDate = pendingRec.date;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSavingsRecommendationDialog(context, state, pendingRec);
      });
    }

    final auth = Provider.of<AuthService>(context);

    Widget buildDrawer() {
      return Drawer(
        backgroundColor: const Color(0xFF0F172A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                border: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Text(
                          auth.currentUserName.isNotEmpty
                              ? auth.currentUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUserName,
                              style: AppTheme.headlineMd.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              auth.currentUser?.email ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: auth.isAdmin ? Colors.amber : Colors.blueGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          auth.isAdminMode
                              ? "PIN ADMIN"
                              : (auth.isAdmin ? "ADMIN" : "WORKER"),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (auth.isAdminMode) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        auth.exitAdminMode();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text(
                              "Lock (Return to Worker)",
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(0, "Daily Setup", Icons.edit_calendar),
                  _buildDrawerTile(1, "Sales Entry", Icons.add_shopping_cart),
                  _buildDrawerTile(2, "Expenses", Icons.payments),
                  _buildDrawerTile(3, "Customer List", Icons.groups),
                  _buildDrawerTile(4, "Daily Summary", Icons.cloud_upload),
                  _buildDrawerTile(5, "Owner Finance", Icons.account_balance),
                  _buildDrawerTile(6, "AI Analyst", Icons.psychology),
                  _buildDrawerTile(7, "History", Icons.history),
                  if (auth.isAdmin)
                    _buildDrawerTile(8, "Admin Panel", Icons.admin_panel_settings),
                  if (auth.isWorker)
                    _buildDrawerTile(
                      -1,
                      "Unlock Admin (PIN)",
                      Icons.lock_open,
                      onTap: () {
                        Navigator.pop(context);
                        _showPinSwitchDialog(context);
                      },
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            PopupMenuButton<String>(
              offset: const Offset(20, -100),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: Colors.white10),
              ),
              onSelected: (val) {
                state.onBusinessChanged(val);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'business_1',
                  child: Text('Business 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const PopupMenuItem(
                  value: 'business_2',
                  child: Text('Business 2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              child: IgnorePointer(
                child: _buildDrawerTile(
                  -2,
                  state.businessId == 'business_1' ? 'Business 1' : 'Business 2',
                  Icons.swap_horiz,
                  onTap: () {},
                ),
              ),
            ),
            _buildDrawerTile(
              -3,
              "Logout",
              Icons.logout,
              onTap: () async {
                Navigator.pop(context);
                final audit = Provider.of<AuditService>(context, listen: false);
                await audit.log(
                  action: 'logout',
                  details: '${auth.currentUserName} logged out',
                );
                await auth.logout();
              },
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Text(
                    _getScreenTitle(_currentIndex),
                    style: AppTheme.headlineLg.copyWith(color: AppTheme.primary),
                  ),
                ],
              ),
              actions: [
                if (auth.isAdminMode)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.amber),
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text("LOCK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => auth.exitAdminMode(),
                  )
                else if (auth.isWorker)
                  IconButton(
                    icon: const Icon(Icons.lock_outline, color: AppTheme.onSurfaceVariant),
                    tooltip: "Admin Unlock (PIN)",
                    onPressed: () => _showPinSwitchDialog(context),
                  ),
                IconButton(
                  icon: const Icon(Icons.sync, color: AppTheme.primary),
                  onPressed: () {
                    // Sync trigger
                    state.triggerSync();
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.5),
                child: Container(
                  color: AppTheme.outlineVariant,
                  height: 1.5,
                ),
              ),
            ),
      drawer: isDesktop ? null : buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) ...[
            Container(
              width: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(right: BorderSide(color: Colors.white10, width: 1.5)),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "LedgerFlow".toUpperCase(),
                        style: AppTheme.headlineLg.copyWith(color: Colors.white, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(color: Colors.white10)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSidebarItem(0, "Daily Setup", Icons.edit_calendar),
                      _buildSidebarItem(1, "Sales Entry", Icons.add_shopping_cart),
                      _buildSidebarItem(2, "Expenses", Icons.payments),
                      _buildSidebarItem(3, "Customer List", Icons.groups),
                      _buildSidebarItem(4, "Daily Summary", Icons.cloud_upload),
                      _buildSidebarItem(5, "Owner Finance", Icons.account_balance),
                      _buildSidebarItem(6, "AI Analyst", Icons.psychology),
                      _buildSidebarItem(7, "History", Icons.history),
                      if (auth.isAdmin)
                        _buildSidebarItem(8, "Admin Panel", Icons.admin_panel_settings),
                      if (auth.isWorker)
                        _buildSidebarItem(
                          -1,
                          "Unlock Admin (PIN)",
                          Icons.lock_open,
                          onTap: () => _showPinSwitchDialog(context),
                        ),
                    ]),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Divider(color: Colors.white10),
                        _buildSidebarItem(
                          -3,
                          "Logout (${auth.currentUserName})",
                          Icons.logout,
                          onTap: () async {
                            final audit = Provider.of<AuditService>(context, listen: false);
                            await audit.log(
                              action: 'logout',
                              details: '${auth.currentUserName} logged out',
                            );
                            await auth.logout();
                          },
                        ),
                        PopupMenuButton<String>(
                          offset: const Offset(20, -100),
                          color: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          onSelected: (val) {
                            state.onBusinessChanged(val);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'business_1',
                              child: Text('Business 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const PopupMenuItem(
                              value: 'business_2',
                              child: Text('Business 2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          child: IgnorePointer(
                            child: _buildSidebarItem(
                              -2,
                              state.businessId == 'business_1' ? 'Business 1' : 'Business 2',
                              Icons.swap_horiz,
                              onTap: () {},
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop || _currentIndex > 4
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 1.5)),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppTheme.surface,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                selectedLabelStyle: AppTheme.labelBold.copyWith(fontSize: 10.0, height: 1.5),
                unselectedLabelStyle: AppTheme.labelBold.copyWith(fontSize: 10.0, height: 1.5),
                iconSize: 28.0,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_outlined),
                    activeIcon: Icon(Icons.inventory, color: AppTheme.primary),
                    label: 'SETUP',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_shipping_outlined),
                    activeIcon: Icon(Icons.local_shipping, color: AppTheme.primary),
                    label: 'SALES',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.payments_outlined),
                    activeIcon: Icon(Icons.payments, color: AppTheme.primary),
                    label: 'EXPENSES',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.groups_outlined),
                    activeIcon: Icon(Icons.groups, color: AppTheme.primary),
                    label: 'CLIENTS',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined),
                    activeIcon: Icon(Icons.analytics, color: AppTheme.primary),
                    label: 'SUMMARY',
                  ),
                ],
              ),
            ),
    );
  }

  void _showPinSwitchDialog(BuildContext context) {
    final pinC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text("Enter Admin PIN",
            style: AppTheme.headlineMd.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter the 4-digit admin PIN to temporarily unlock administrative controls.",
              style: AppTheme.bodyMd.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinC,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: AppTheme.headlineMd
                  .copyWith(color: Colors.white, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              final audit = Provider.of<AuditService>(context, listen: false);
              final success = await auth.switchToAdminWithPin(pinC.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) {
                await audit.log(
                  action: 'pin_unlock',
                  details: '${auth.currentUserName} unlocked admin mode via PIN',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Admin mode unlocked!")),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Invalid PIN or PIN not configured")),
                  );
                }
              }
            },
            child: const Text("UNLOCK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return "Daily Setup";
      case 1:
        return "Sales Entry";
      case 2:
        return "Expenditure";
      case 3:
        return "Active Customers";
      case 4:
        return "Summary";
      case 5:
        return "Owner Finance";
      case 6:
        return "AI Analyst";
      case 7:
        return "History";
      case 8:
        return "Admin Panel";
      default:
        return "LedgerFlow";
    }
  }

  Widget _buildDrawerTile(int index, String label, IconData icon, {VoidCallback? onTap}) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8)),
      title: Text(
        label,
        style: AppTheme.bodyLg.copyWith(
          color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryContainer,
      onTap: onTap ?? () {
        if (index >= 0) {
          setState(() {
            _currentIndex = index;
          });
        }
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon, {VoidCallback? onTap}) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap ?? () {
          if (index >= 0) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
                size: 24.0,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyLg.copyWith(
                    color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavingsRecommendationDialog(
    BuildContext context,
    LedgerState state,
    SavingsRecommendation rec,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isEditing = false;
        final TextEditingController amountController =
            TextEditingController(text: rec.suggestedSavings.toString());
        String? inputError;

        return Consumer<LedgerState>(
          builder: (context, ledgerState, child) {
            // Check if the recommendation is still pending. If not (processed by another device), dismiss dialog automatically.
            final currentRec = ledgerState.pendingRecommendation;
            if (currentRec == null || currentRec.date != rec.date) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
              return const SizedBox.shrink();
            }

            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                  ),
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title Header
                        Row(
                          children: [
                            const Icon(Icons.savings_outlined, color: AppTheme.primary, size: 24.0),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                "DAILY SAVINGS ADVISOR",
                                style: AppTheme.headlineMd.copyWith(
                                  color: AppTheme.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        const Divider(color: AppTheme.outlineVariant, height: 1.0),
                        const SizedBox(height: 20.0),

                        if (!isEditing) ...[
                          // Recommended amount display
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "₹${rec.suggestedSavings}",
                                  style: AppTheme.headlineXl.copyWith(
                                    fontSize: 44.0,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  "RECOMMENDED DAILY MICRO-SAVINGS",
                                  style: AppTheme.labelSm.copyWith(
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          // Explanation/Reasoning
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              border: Border.all(color: AppTheme.outlineVariant, width: 1.0),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Text(
                              rec.conversationalReason,
                              style: AppTheme.bodyMd.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 28.0),

                          // Button 1: Transfer Recommended Amount
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await state.executeSavingsTransfer(rec.date, rec.suggestedSavings);
                              await HapticFeedback.lightImpact();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "TRANSFER ₹${rec.suggestedSavings}",
                              style: AppTheme.labelBold.copyWith(color: Colors.white, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          // Button 2: Edit Amount
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                isEditing = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            child: Text(
                              "EDIT AMOUNT",
                              style: AppTheme.labelBold.copyWith(color: AppTheme.primary, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          // Button 3: Don't Transfer
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await state.skipSavingsRecommendation(rec.date);
                            },
                            child: Text(
                              "DON'T TRANSFER",
                              style: AppTheme.labelBold.copyWith(
                                color: AppTheme.error,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Edit Mode view
                          Text(
                            "ENTER SAVINGS AMOUNT (₹)",
                            style: AppTheme.labelSm.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: "e.g., ${rec.suggestedSavings}",
                              errorText: inputError,
                              prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.onSurface),
                              filled: true,
                              fillColor: AppTheme.surfaceContainerLow,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
                              ),
                              errorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.error, width: 1.5),
                              ),
                              focusedErrorBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.error, width: 2.0),
                              ),
                            ),
                            style: AppTheme.headlineMd.copyWith(fontSize: 22.0),
                          ),
                          const SizedBox(height: 24.0),

                          // Confirm Action
                          ElevatedButton(
                            onPressed: () async {
                              final text = amountController.text.trim();
                              final val = int.tryParse(text);
                              if (val == null || val <= 0) {
                                setState(() {
                                  inputError = "Enter a valid positive amount";
                                });
                                return;
                              }
                              Navigator.pop(context);
                              await state.executeSavingsTransfer(rec.date, val);
                              await HapticFeedback.lightImpact();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "CONFIRM TRANSFER",
                              style: AppTheme.labelBold.copyWith(color: Colors.white, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 12.0),

                          // Cancel Edit
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                                inputError = null;
                                amountController.text = rec.suggestedSavings.toString();
                              });
                            },
                            child: Text(
                              "CANCEL",
                              style: AppTheme.labelBold.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

