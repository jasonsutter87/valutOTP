import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/folders_provider.dart';
import 'scan_qr_screen.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();

  String? _selectedFolderId;
  bool _showAdvanced = false;
  int _digits = 6;
  int _period = 30;
  Algorithm _algorithm = Algorithm.sha1;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan QR button
            OutlinedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Divider with "or"
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or enter manually',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 24),

            // Manual entry form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Name *',
                      hintText: 'e.g., user@example.com',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Issuer
                  TextFormField(
                    controller: _issuerController,
                    decoration: const InputDecoration(
                      labelText: 'Issuer (optional)',
                      hintText: 'e.g., GitHub, AWS, Google',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secret
                  TextFormField(
                    controller: _secretController,
                    decoration: const InputDecoration(
                      labelText: 'Secret Key *',
                      hintText: 'e.g., JBSWY3DPEHPK3PXP',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the secret key';
                      }
                      // Basic validation - secret should be base32
                      final cleaned = value.replaceAll(' ', '').toUpperCase();
                      if (!RegExp(r'^[A-Z2-7]+=*$').hasMatch(cleaned)) {
                        return 'Invalid secret key format';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Folder selection
                  foldersAsync.when(
                    data: (folders) {
                      if (folders.isEmpty) return const SizedBox.shrink();

                      return DropdownButtonFormField<String?>(
                        value: _selectedFolderId,
                        decoration: const InputDecoration(
                          labelText: 'Folder (optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No folder'),
                          ),
                          ...folders.map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(f.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedFolderId = value);
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Advanced options toggle
                  TextButton(
                    onPressed: () {
                      setState(() => _showAdvanced = !_showAdvanced);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_showAdvanced ? 'Hide advanced' : 'Show advanced'),
                        Icon(_showAdvanced
                            ? Icons.expand_less
                            : Icons.expand_more),
                      ],
                    ),
                  ),

                  // Advanced options
                  if (_showAdvanced) ...[
                    const SizedBox(height: 8),

                    // Digits
                    DropdownButtonFormField<int>(
                      value: _digits,
                      decoration: const InputDecoration(
                        labelText: 'Digits',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 6, child: Text('6')),
                        DropdownMenuItem(value: 8, child: Text('8')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _digits = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Period
                    DropdownButtonFormField<int>(
                      value: _period,
                      decoration: const InputDecoration(
                        labelText: 'Period (seconds)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30')),
                        DropdownMenuItem(value: 60, child: Text('60')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _period = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Algorithm
                    DropdownButtonFormField<Algorithm>(
                      value: _algorithm,
                      decoration: const InputDecoration(
                        labelText: 'Algorithm',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: Algorithm.sha1, child: Text('SHA1')),
                        DropdownMenuItem(
                            value: Algorithm.sha256, child: Text('SHA256')),
                        DropdownMenuItem(
                            value: Algorithm.sha512, child: Text('SHA512')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _algorithm = value);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add Account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ScanQRScreen(folderId: _selectedFolderId),
      ),
    );

    if (result != null && mounted) {
      // Add all accounts from the scan result
      for (final account in result.accounts) {
        await ref.read(accountsProvider.notifier).addAccount(account);
      }

      if (mounted) {
        // Show success message for imports
        if (result.isGoogleImport && result.accounts.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${result.accounts.length} accounts!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final account = Account.create(
      name: _nameController.text.trim(),
      issuer: _issuerController.text.trim().isEmpty
          ? null
          : _issuerController.text.trim(),
      secret: _secretController.text.trim(),
      folderId: _selectedFolderId,
      digits: _digits,
      period: _period,
      algorithm: _algorithm,
    );

    await ref.read(accountsProvider.notifier).addAccount(account);

    if (mounted) Navigator.pop(context);
  }
}
