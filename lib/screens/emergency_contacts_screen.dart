import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/widgets/bsas_card.dart';
import '../core/widgets/bsas_text_field.dart';
import '../core/widgets/status_badge.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contacts_repository.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key, this.repository, this.initialContacts});

  final EmergencyContactsRepository? repository;
  final List<EmergencyContact>? initialContacts;

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final EmergencyContactsRepository _repo;
  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? EmergencyContactsRepository();
    if (widget.initialContacts != null) {
      _contacts = List.from(widget.initialContacts!);
      _loading = false;
    }
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    final list = await _repo.loadAllContacts();
    if (mounted) {
      setState(() {
        _contacts = list;
        _loading = false;
      });
    }
  }

  void _showAddEditDialog([EmergencyContact? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
    final relCtrl = TextEditingController(text: existing?.relationship ?? 'Family / Contact');
    bool waEnabled = existing?.whatsappEnabled ?? true;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: BsasColors.darkSurface,
            title: Text(
              existing == null ? 'Add Emergency Contact' : 'Edit Contact',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BSASTextField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    hintText: 'e.g. Inspector Ramesh / Brother',
                  ),
                  const SizedBox(height: 12),
                  BSASTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    hintText: '+91 9876543210 or 10-digit mobile',
                    keyboardType: TextInputType.phone,
                    errorText: errorText,
                  ),
                  const SizedBox(height: 12),
                  BSASTextField(
                    controller: relCtrl,
                    label: 'Relationship / Role',
                    hintText: 'e.g. Police / Forest Dept / Family',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable WhatsApp Sharing', style: TextStyle(color: Colors.white, fontSize: 13)),
                    subtitle: const Text('Include in WhatsApp emergency handoff', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    value: waEnabled,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (val) => setDialogState(() => waEnabled = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: BsasColors.radarCyan),
                onPressed: () async {
                  final validationError = EmergencyContact.validatePhoneNumber(phoneCtrl.text);
                  if (validationError != null) {
                    setDialogState(() => errorText = validationError);
                    return;
                  }

                  final contact = EmergencyContact(
                    id: existing?.id ?? 'contact_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim().isEmpty ? 'Emergency Contact' : nameCtrl.text.trim(),
                    phoneNumber: EmergencyContact.formatForDialing(phoneCtrl.text),
                    relationship: relCtrl.text.trim().isEmpty ? 'Contact' : relCtrl.text.trim(),
                    whatsappEnabled: waEnabled,
                    isActive: existing?.isActive ?? true,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  );

                  await _repo.saveContact(contact);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (mounted) {
                    _loadContacts();
                  }
                },
                child: Text(existing == null ? 'Save' : 'Update', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact c) async {
    await _repo.deleteContact(c.id);
    _loadContacts();
  }

  Future<void> _toggleContactActive(EmergencyContact c, bool active) async {
    await _repo.toggleActive(c.id, active);
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BsasColors.darkBg,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Emergency Contacts', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: BsasColors.radarCyan),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contact_phone_outlined, size: 64, color: Colors.white30),
                      const SizedBox(height: 16),
                      const Text('No Emergency Contacts Saved', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Add contacts to receive immediate SOS alerts', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: BsasColors.radarCyan),
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text('Add First Contact', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddEditDialog(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, i) {
                    final c = _contacts[i];
                    return BsasCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      title: c.name,
                      status: StatusBadge(
                        label: c.isActive ? 'ACTIVE' : 'MUTED',
                        color: c.isActive ? BsasColors.safeGreen : Colors.white38,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, color: BsasColors.radarCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(c.phoneNumber, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (c.whatsappEnabled)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.chat_rounded, color: Colors.greenAccent, size: 18),
                                ),
                              Switch(
                                value: c.isActive,
                                activeThumbColor: BsasColors.safeGreen,
                                onChanged: (val) => _toggleContactActive(c, val),
                              ),
                            ],
                          ),
                          Text(c.relationship, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const Divider(color: Colors.white12, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                                label: const Text('Edit', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                onPressed: () => _showAddEditDialog(c),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 16, color: BsasColors.dangerRed),
                                label: const Text('Delete', style: TextStyle(color: BsasColors.dangerRed, fontSize: 12)),
                                onPressed: () => _deleteContact(c),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
