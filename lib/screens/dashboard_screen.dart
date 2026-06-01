import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';
import 'login_screen.dart';
import 'inventory_tab.dart';
import 'checkout_tab.dart';
import 'job_order_tab.dart';
import 'schedule_tab.dart';
import 'schedule_tab.dart';
import 'mix_match_tab.dart';
import 'employee_tab.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  void _onLogout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final primaryColor = Colors.purple[900]!;
    final isMobile = ResponsiveLayout.isMobile(context);

    final List<Widget> tabs = [
      const InventoryTab(),
      const MixMatchTab(),
      const CheckoutTab(),
      const JobOrderTab(),
      const ScheduleTab(),
      if (user?.isOwner == true) const EmployeeTab(),
    ];

    final List<String> titles = [
      'Product Catalogue & Inventory',
      'Catalogue Mix & Match',
      'POS Mix-and-Match Checkout',
      'Production & Alteration Jobs',
      'Reservation Schedule Calendar',
      if (user?.isOwner == true) 'Employee Management',
    ];

    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
    }

    Widget buildAppBar() {
      final displayTitle = isMobile
          ? [
              'Inventory',
              'Mix & Match',
              'POS Checkout',
              'Job Orders',
              'Schedule',
              if (user?.isOwner == true) 'Employees',
            ][_selectedIndex]
          : titles[_selectedIndex];

      return AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (isMobile && _appVersion.isNotEmpty)
              Text(
                'v$_appVersion',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: '${user?.name} (${user?.isOwner == true ? 'Owner' : 'Worker'})',
                child: CircleAvatar(
                  backgroundColor: Colors.purple[50],
                  radius: 16,
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(
                  '${user?.name} (${user?.isOwner == true ? 'Owner' : 'Worker'})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.purple[50],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      );
    }

    // Mobile layout: bottom navigation bar
    Widget mobileLayout() {
      return Scaffold(
        appBar: buildAppBar() as PreferredSizeWidget?,
        body: tabs[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(Icons.style),
              label: 'Mix & Match',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_checkout_outlined),
              activeIcon: Icon(Icons.shopping_cart_checkout),
              label: 'Checkout',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Job Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.date_range_outlined),
              activeIcon: Icon(Icons.date_range),
              label: 'Schedule',
            ),
            if (user?.isOwner == true)
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Employees',
              ),
          ],
        ),
      );
    }

    // Tablet/Desktop layout: side navigation rail
    Widget tabletLayout() {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: primaryColor),
              selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              unselectedIconTheme: const IconThemeData(color: Colors.black54),
              unselectedLabelTextStyle: const TextStyle(color: Colors.black54),
              backgroundColor: Colors.white,
              elevation: 4,
              leading: Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 32.0),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.purple[50],
                  child: Icon(Icons.auto_awesome_mosaic_outlined, color: primaryColor, size: 28),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_appVersion.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text('v$_appVersion', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.power_settings_new_outlined, color: Colors.redAccent, size: 28),
                          tooltip: 'Logout',
                          onPressed: _onLogout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Inventory'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style),
                  label: Text('Mix & Match'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart_checkout_outlined),
                  selectedIcon: Icon(Icons.shopping_cart_checkout),
                  label: Text('Checkout'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text('Job Orders'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.date_range_outlined),
                  selectedIcon: Icon(Icons.date_range),
                  label: Text('Schedule'),
                ),
                if (user?.isOwner == true)
                  const NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Employees'),
                  ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                appBar: buildAppBar() as PreferredSizeWidget?,
                body: Container(
                  color: Colors.grey[50],
                  child: tabs[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: mobileLayout(),
        tabletBody: tabletLayout(),
      ),
    );
  }
}
