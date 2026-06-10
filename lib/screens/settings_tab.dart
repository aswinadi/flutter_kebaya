import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rental_provider.dart';
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
    final primaryColor = Colors.purple[900]!;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
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
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 20),
                      
                      // Lock period setting
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
                      const SizedBox(height: 32),
                      
                      // Submit button
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
            ),
          ),
        ),
      ),
    );
  }
}
