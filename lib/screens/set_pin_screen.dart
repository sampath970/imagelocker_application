import 'package:flutter/material.dart';
import '../utils/pin_helper.dart';

class SetPinScreen extends StatefulWidget {
  final VoidCallback? onPinSet;
  const SetPinScreen({super.key, this.onPinSet});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isSaving = false;

  void _savePin() async {
    if (_pinController.text.trim().isEmpty) return _showMsg("Enter a PIN");
    if (_pinController.text != _confirmPinController.text) return _showMsg("PINs do not match");

    setState(() => _isSaving = true);
    await PinHelper.savePin(_pinController.text.trim());
    setState(() => _isSaving = false);

    widget.onPinSet?.call();
    if (mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Your PIN")),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Please create a secure PIN to lock/unlock your app.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter PIN"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Confirm PIN"),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePin,
                child: Text(_isSaving ? "Saving..." : "Set PIN"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
