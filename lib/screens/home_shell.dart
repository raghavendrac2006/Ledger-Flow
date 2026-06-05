import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import 'setup_screen.dart';
import 'sales_entry_screen.dart';
import 'expenses_screen.dart';
import 'client_list_screen.dart';
import 'summary_screen.dart';
import 'owner_finance_screen.dart';
import 'ai_analyst_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

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
    ];
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
              child: Center(
                child: Text(
                  "Delivery Pro".toUpperCase(),
                  style: AppTheme.headlineLg.copyWith(color: Colors.white, letterSpacing: 1.5),
                ),
              ),
            ),
            _buildDrawerTile(0, "Daily Setup", Icons.edit_calendar),
            _buildDrawerTile(1, "Sales Entry", Icons.add_shopping_cart),
            _buildDrawerTile(2, "Expenses", Icons.payments),
            _buildDrawerTile(3, "Customer List", Icons.groups),
            _buildDrawerTile(4, "Daily Summary", Icons.cloud_upload),
            _buildDrawerTile(5, "Owner Finance", Icons.account_balance),
            _buildDrawerTile(6, "AI Analyst", Icons.psychology),
            const Spacer(),
            const Divider(color: Colors.white10),
            _buildDrawerTile(-1, "Reset Rounds", Icons.refresh, onTap: () {
              state.resetRounds();
              setState(() {
                _currentIndex = 0;
              });
              Navigator.pop(context);
            }),
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
                        "Delivery Pro".toUpperCase(),
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
                    ]),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Divider(color: Colors.white10),
                        _buildSidebarItem(-1, "Reset Rounds", Icons.refresh, onTap: () {
                          state.resetRounds();
                          setState(() {
                            _currentIndex = 0;
                          });
                        }),
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
      default:
        return "Delivery Pro";
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
        setState(() {
          _currentIndex = index;
        });
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
          setState(() {
            _currentIndex = index;
          });
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
}

