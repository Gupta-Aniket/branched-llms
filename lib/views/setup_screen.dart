import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';

class SetupScreen extends StatelessWidget {
  final ChatController controller = Get.find();
  final TextEditingController apiKeyController = TextEditingController();
  final RxString selectedProvider = 'OpenAI'.obs;

  SetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if already configured
    if (controller.isConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed('/chat');
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Chat MVP',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your AI provider to get started',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // Provider Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select AI Provider',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() => Column(
                        children: [
                          _buildProviderTile('OpenAI', Icons.psychology),
                          _buildProviderTile('Gemini', Icons.auto_awesome),
                          _buildProviderTile('Claude', Icons.smart_toy),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // API Key Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Key',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your API key',
                          prefixIcon: const Icon(Icons.key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderTile(String provider, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(provider),
        ],
      ),
      value: provider,
      groupValue: selectedProvider.value,
      onChanged: (value) => selectedProvider.value = value!,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _handleContinue() async {
    if (apiKeyController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your API key',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    await controller.saveApiConfiguration(
      apiKeyController.text.trim(),
      selectedProvider.value,
    );

    Get.offNamed('/chat');
  }
}
