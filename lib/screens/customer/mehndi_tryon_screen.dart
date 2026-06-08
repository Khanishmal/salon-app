import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/makeup_provider.dart';

class MehndiTryOnScreen extends StatelessWidget {
  // Fixed linting error: converted key initialization to modern super parameter syntax
  const MehndiTryOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mehndi Studio Try-On'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'AR Overlay Viewport Placeholder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.black.withOpacity(0.85),
            child: Consumer<MakeupProvider>(
              builder: (context, provider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Adjust Mehndi Intensity',
                      style: TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: provider.configuration.mehndiOpacity, // Fixed undefined getter
                      min: 0.0,
                      max: 1.0,
                      activeColor: provider.configuration.mehndiColor,
                      onChanged: (newValue) {
                        provider.updateOpacity('mehndi', newValue);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}