import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';
import 'login_screen.dart';
import 'inventory_tab.dart';
import 'checkout_tab.dart';
import 'job_order_tab.dart';
import 'schedule_tab.dart';
import 'mix_match_tab.dart';
import 'employee_tab.dart';
import 'settings_tab.dart';
import 'rentals_tab.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/profile_dialog.dart';

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
      const RentalsTab(),
      const JobOrderTab(),
      const ScheduleTab(),
      if (user?.isOwner == true) const EmployeeTab(),
      if (user?.isOwner == true) const SettingsTab(),
    ];

    final List<String> titles = [
      'Katalog Produk & Inventaris',
      'Padu Padan Katalog',
      'Kasir Padu Padan POS',
      'Daftar Transaksi Penyewaan',
      'Pekerjaan Produksi & Permak',
      'Kalender Jadwal Reservasi',
      if (user?.isOwner == true) 'Manajemen Karyawan',
      if (user?.isOwner == true) 'Pengaturan Sistem',
    ];

    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
    }

    Widget buildAppBar() {
      final displayTitle = isMobile
          ? [
              'Inventaris',
              'Padu Padan',
              'Kasir',
              'Transaksi',
              'Pekerjaan',
              'Jadwal',
              if (user?.isOwner == true) 'Karyawan',
              if (user?.isOwner == true) 'Pengaturan',
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
                message: '${user?.name} (${user?.isOwner == true ? 'Pemilik' : 'Karyawan'})',
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ProfileDialog(),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.purple[50],
                    radius: 16,
                    child: Text(
                      (user?.name ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ActionChip(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ProfileDialog(),
                  );
                },
                avatar: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(
                  '${user?.name} (${user?.isOwner == true ? 'Pemilik' : 'Karyawan'})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.purple[50],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
            tooltip: 'Keluar',
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
              label: 'Inventaris',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(Icons.style),
              label: 'Padu Padan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_checkout_outlined),
              activeIcon: Icon(Icons.shopping_cart_checkout),
              label: 'Kasir',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transaksi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Pekerjaan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.date_range_outlined),
              activeIcon: Icon(Icons.date_range),
              label: 'Jadwal',
            ),
            if (user?.isOwner == true)
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Karyawan',
              ),
            if (user?.isOwner == true)
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Pengaturan',
              ),
          ],
        ),
      );
    }

    // Tablet/Desktop layout: side navigation rail
    Widget tabletLayout() {
      final List<SidebarDestination> sidebarDestinations = [
        SidebarDestination(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: 'Inventaris',
          index: 0,
        ),
        SidebarDestination(
          icon: Icons.style_outlined,
          selectedIcon: Icons.style,
          label: 'Padu Padan',
          index: 1,
        ),
        SidebarDestination(
          icon: Icons.shopping_cart_checkout_outlined,
          selectedIcon: Icons.shopping_cart_checkout,
          label: 'Kasir',
          index: 2,
        ),
        SidebarDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Transaksi',
          index: 3,
        ),
        SidebarDestination(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          label: 'Pekerjaan',
          index: 4,
        ),
        SidebarDestination(
          icon: Icons.date_range_outlined,
          selectedIcon: Icons.date_range,
          label: 'Jadwal',
          index: 5,
        ),
        if (user?.isOwner == true)
          SidebarDestination(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Karyawan',
            index: 6,
          ),
        if (user?.isOwner == true)
          SidebarDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Pengaturan',
            index: 7,
          ),
      ];

      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 84,
              color: Colors.white,
              child: Column(
                children: [
                  // Leading (Avatar)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.purple[50],
                      child: Icon(Icons.auto_awesome_mosaic_outlined, color: primaryColor, size: 24),
                    ),
                  ),
                  
                  // Destinations (Scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: sidebarDestinations.map((dest) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SidebarItem(
                              icon: dest.icon,
                              selectedIcon: dest.selectedIcon,
                              label: dest.label,
                              isSelected: _selectedIndex == dest.index,
                              onTap: () => setState(() => _selectedIndex = dest.index),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  // Trailing (Version & Logout)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_appVersion.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text('v$_appVersion', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.power_settings_new_outlined, color: Colors.redAccent, size: 24),
                          tooltip: 'Keluar',
                          onPressed: _onLogout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

class SidebarDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  SidebarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
  });
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.purple[900]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? primaryColor : Colors.black54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
