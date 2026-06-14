import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rental_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final _lockPeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rentalProvider = Provider.of<RentalProvider>(context, listen: false);
      rentalProvider.fetchSettings().then((_) {
        _lockPeriodController.text = rentalProvider.dateLockingPeriod.toString();
      });
    });
  }

  @override
  void dispose() {
    _lockPeriodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = Provider.of<RentalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isOwner = user?.isOwner == true;
    final primaryColor = Colors.purple[900]!;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 28, color: primaryColor),
                            const SizedBox(width: 12),
                            const Text(
                              'Profil Pengguna',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.purple[50],
                              child: Text(
                                (user?.name ?? 'U')[0].toUpperCase(),
                                style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Nama Pengguna',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? 'email@example.com',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      isOwner ? 'Pemilik Toko (Owner)' : 'Karyawan',
                                      style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Settings / Restriction Card
                if (isOwner)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings_outlined, size: 28, color: primaryColor),
                                const SizedBox(width: 12),
                                const Text(
                                  'Pengaturan Sistem',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _lockPeriodController,
                              decoration: const InputDecoration(
                                labelText: 'Durasi Kunci Tanggal Reservasi (Hari)',
                                border: OutlineInputBorder(),
                                helperText: 'Default: 7 hari. Menentukan batas aman pemesanan ganda.',
                                prefixIcon: Icon(Icons.date_range_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Wajib diisi';
                                }
                                final parsed = int.tryParse(value);
                                if (parsed == null || parsed < 0) {
                                  return 'Masukkan angka hari yang valid (minimal 0)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save_outlined),
                                label: const Text(
                                  'Simpan Pengaturan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: rentalProvider.isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) return;
                                        
                                        final val = int.parse(_lockPeriodController.text);
                                        final success = await rentalProvider.updateDateLockingPeriod(val);
                                        
                                        if (mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Pengaturan berhasil disimpan'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Gagal menyimpan: ${rentalProvider.error}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 2,
                    color: Colors.amber[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.amber[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800], size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Akses Terbatas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Hanya pemilik toko (Owner) yang memiliki otorisasi untuk mengubah pengaturan durasi kunci tanggal reservasi sistem.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber[900],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
