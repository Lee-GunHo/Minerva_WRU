import 'package:flutter/material.dart';
import '../core/app_typo.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('최근 통화기록', style: AppTypo.body.copyWith(fontWeight: FontWeight.w600))),
      body: const Center(child: Text('최근기록 화면 (추가 예정)')),
    );
  }
}
