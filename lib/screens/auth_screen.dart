import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onUnlock; // Enable autolock callback support

  const AuthScreen({super.key, this.onUnlock});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    try {
      bool canCheck = await auth.canCheckBiometrics;
      if (!canCheck) {
        _showError('No biometrics available on this device.');
        setState(() => _isAuthenticating = false);
        return;
      }
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock memories',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) {
        // Autolock integration: call onUnlock if provided
        widget.onUnlock?.call();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Authentication failed. Try again.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
    setState(() => _isAuthenticating = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToPin() {
    Navigator.pushReplacementNamed(context, '/pin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Memories'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Please authenticate to continue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(_isAuthenticating ? 'Authenticating...' : 'Unlock'),
                onPressed: _isAuthenticating ? null : _authenticate,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isAuthenticating ? null : _navigateToPin,
              child: const Text('Use PIN Instead'),
            ),
          ],
        ),
      ),
    );
  }
}
