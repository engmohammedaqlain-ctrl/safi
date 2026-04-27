import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import 'add_customer_detail_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    
    if (await FlutterContacts.requestPermission()) {
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
      
      // Filter out contacts without a phone number
      contacts = contacts.where((c) => c.phones.isNotEmpty).toList();
      
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
        _permissionDenied = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
    }
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredContacts = _contacts);
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(lowerQuery);
        final phoneMatch = c.phones.any((p) => p.number.contains(lowerQuery));
        return nameMatch || phoneMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('إضافة عميل', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerDetailScreen()));
                },
                child: const Text('إضافة عميل جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('جهات الاتصال', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                onChanged: _filterContacts,
                decoration: const InputDecoration(
                  hintText: 'البحث',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(LucideIcons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _permissionDenied
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('صلاحية الوصول لجهات الاتصال مطلوبة', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => openAppSettings(),
                              child: const Text('فتح الإعدادات لمنح الصلاحية'),
                            ),
                          ],
                        ),
                      )
                    : _filteredContacts.isEmpty
                        ? const Center(child: Text('لا توجد جهات اتصال مطابقة', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : ListView.separated(
                            itemCount: _filteredContacts.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(contact.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                subtitle: Text(phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                trailing: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.plus, color: AppColors.primary, size: 20),
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddCustomerDetailScreen(
                                    initialName: contact.displayName,
                                    initialPhone: phone,
                                  )));
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
