import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/rental_provider.dart';
import '../widgets/responsive_layout.dart';

class HomeTab extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeTab({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentalProvider>(context, listen: false).fetchRentals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final rentalProvider = Provider.of<RentalProvider>(context);
    final user = auth.user;
    final primaryColor = Colors.purple[900]!;
    final isMobile = ResponsiveLayout.isMobile(context);

    // Filter active rentals (booked / picked_up)
    final activeRentalsCount = rentalProvider.rentals
        .where((r) => r.status == 'booked' || r.status == 'picked_up')
        .length;

    final todayStr = DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now());

    // Define dashboard cards
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Kasir POS',
        'desc': 'Pemesanan baru & pembayaran',
        'icon': Icons.shopping_cart_checkout_outlined,
        'color': Colors.deepPurple[700]!,
        'index': 4,
        'visible': true,
      },
      {
        'title': 'Padu Padan',
        'desc': 'Simulasi setelan kebaya',
        'icon': Icons.style_outlined,
        'color': Colors.indigo[700]!,
        'index': 5,
        'visible': true,
      },
      {
        'title': 'Katalog & Stok',
        'desc': 'Kelola pakaian & aksesoris',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.blue[700]!,
        'index': 6,
        'visible': true,
      },
      {
        'title': 'Tugas Tailor',
        'desc': 'Kelola pekerjaan produksi',
        'icon': Icons.handyman_outlined,
        'color': Colors.amber[800]!,
        'index': 7,
        'visible': true,
      },
      {
        'title': 'Karyawan',
        'desc': 'Manajemen staf & akun',
        'icon': Icons.people_outline,
        'color': Colors.teal[700]!,
        'index': 8,
        'visible': user?.isOwner == true,
      },
    ];

    final visibleItems = menuItems.where((item) => item['visible'] == true).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => rentalProvider.fetchRentals(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple[900]!,
                      Colors.deepPurple[700]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? 'Pengguna',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              user?.isOwner == true ? 'Pemilik Toko' : 'Karyawan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amber[300],
                      size: 60,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Stats Section
              Row(
                children: [
                  // Stat 1: Date
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[50],
                              radius: 18,
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Hari Ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              todayStr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stat 2: Active Rentals
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.purple[50],
                              radius: 18,
                              child: Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.purple[700],
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Pemesanan Aktif',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rentalProvider.isLoading
                                  ? '...'
                                  : '$activeRentalsCount Transaksi',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Grid Navigation Section
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.15 : 1.3,
                ),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  final cardColor = item['color'] as Color;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => widget.onNavigate(item['index'] as int),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor: cardColor.withOpacity(0.1),
                                  radius: 20,
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: cardColor,
                                    size: 22,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
