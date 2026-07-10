import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class EmployeeTab extends StatefulWidget {
  const EmployeeTab({Key? key}) : super(key: key);

  @override
  State<EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<EmployeeTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<User> _users = [];
  List<String> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _api.getUsers();
      final roles = await _api.getRoles();
      setState(() {
        _users = users;
        _availableRoles = roles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddUserModal() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    List<String> selectedRoles = [];
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Tambah Karyawan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama'),
                    ),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Pengguna (Username)'),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Kata Sandi (Password)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Aktif'),
                      value: isActive,
                      onChanged: (bool value) {
                        setStateModal(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Peran (Roles)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ..._availableRoles.map((role) {
                      return CheckboxListTile(
                        title: Text(role.toUpperCase()),
                        value: selectedRoles.contains(role),
                        onChanged: (bool? checked) {
                          setStateModal(() {
                            if (checked == true) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || usernameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty || selectedRoles.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan isi semua kolom dan pilih minimal satu peran')));
                      return;
                    }
                    try {
                      await _api.createUser(
                        name: nameCtrl.text,
                        username: usernameCtrl.text,
                        email: emailCtrl.text,
                        password: passwordCtrl.text,
                        roles: selectedRoles,
                        isActive: isActive,
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        _fetchData();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserModal(User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final usernameCtrl = TextEditingController(text: user.username);
    final emailCtrl = TextEditingController(text: user.email);
    final passwordCtrl = TextEditingController();
    List<String> selectedRoles = List<String>.from(user.roles);
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: Text('Edit Karyawan: ${user.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama'),
                    ),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Pengguna (Username)'),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kata Sandi Baru (Kosongkan jika tidak diubah)',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Aktif'),
                      value: isActive,
                      onChanged: (bool value) {
                        setStateModal(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Peran (Roles)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ..._availableRoles.map((role) {
                      return CheckboxListTile(
                        title: Text(role.toUpperCase()),
                        value: selectedRoles.contains(role),
                        onChanged: (bool? checked) {
                          setStateModal(() {
                            if (checked == true) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || usernameCtrl.text.isEmpty || emailCtrl.text.isEmpty || selectedRoles.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan isi semua kolom data diri dan pilih minimal satu peran')));
                      return;
                    }
                    try {
                      await _api.updateUser(
                        user.id,
                        name: nameCtrl.text,
                        username: usernameCtrl.text,
                        email: emailCtrl.text,
                        password: passwordCtrl.text.isNotEmpty ? passwordCtrl.text : null,
                        roles: selectedRoles,
                        isActive: isActive,
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data karyawan berhasil diperbarui')),
                        );
                        _fetchData();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple[100],
                child: Text(user.name[0].toUpperCase()),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.email} | @${user.username}'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...user.roles.map((r) => Chip(
                        label: Text(r.toUpperCase(), style: const TextStyle(fontSize: 9)),
                        backgroundColor: r == 'owner' || r == 'super_admin' ? Colors.red[100] : Colors.green[100],
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                      if (!user.isActive)
                        Chip(
                          label: const Text('NON-AKTIF', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.purple[900]),
                onPressed: () => _showEditUserModal(user),
                tooltip: 'Edit Karyawan',
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserModal,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Karyawan'),
      ),
    );
  }
}
