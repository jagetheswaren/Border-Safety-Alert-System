import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen-about'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('About BSAS', style: BsasTypography.headline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Column(
              children: [
                BsasLogo(size: 88, animated: false),
                SizedBox(height: 16),
                Text(
                  'BORDER SAFETY ALERT SYSTEM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Release v1.1.0 • Production Build',
                  style: TextStyle(color: BsasColors.safeGreen, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Offline-First Civilian Border Safety & Perimeter Alert System',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _header('SYSTEM ARCHITECTURE'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.phone_android, color: BsasColors.radarCyan),
                  title: Text('Mobile Core', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Flutter 3.12 / Dart / Android ARM64 release', style: TextStyle(color: Colors.white70)),
                ),
                Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: Icon(Icons.memory, color: BsasColors.radarCyan),
                  title: Text('On-Device ML Engine', style: TextStyle(color: Colors.white)),
                  subtitle: Text('LSTM TFLite (1x5x6) + Random Forest + RobustScaler', style: TextStyle(color: Colors.white70)),
                ),
                Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: Icon(Icons.psychology, color: BsasColors.radarCyan),
                  title: Text('Local Generative AI', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Qwen3-0.6B-Q4_0 GGUF (llama.cpp) / Ollama GPU Bridge', style: TextStyle(color: Colors.white70)),
                ),
                Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: Icon(Icons.map, color: BsasColors.radarCyan),
                  title: Text('Mapping Subsystem', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Offline Raster Storage + Esri World Imagery Satellite', style: TextStyle(color: Colors.white70)),
                ),
                Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: Icon(Icons.storage, color: BsasColors.radarCyan),
                  title: Text('Local Persistence', style: TextStyle(color: Colors.white)),
                  subtitle: Text('SQLite native database + encrypted JSON fallback', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _header('PROJECT & REPOSITORY'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.code, color: BsasColors.safeGreen),
                  title: Text('GitHub Repository', style: TextStyle(color: Colors.white)),
                  subtitle: Text('jagetheswaren/Border-Safety-Alert-System', style: TextStyle(color: Colors.white70)),
                ),
                Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: Icon(Icons.balance, color: BsasColors.safeGreen),
                  title: Text('Software License', style: TextStyle(color: Colors.white)),
                  subtitle: Text('MIT License (BSAS Core) • Apache-2.0 (Qwen AI)', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: BsasTypography.caption.copyWith(
          color: BsasColors.radarCyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
