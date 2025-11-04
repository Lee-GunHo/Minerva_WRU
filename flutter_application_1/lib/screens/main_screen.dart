import 'package:flutter/material.dart';
import '../core/app_typo.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('메인화면', style: AppTypo.body.copyWith(fontWeight: FontWeight.w600))),
      body: const Center(child: Text('메인 대시보드 (추가 예정)')),
    );
  }
}
