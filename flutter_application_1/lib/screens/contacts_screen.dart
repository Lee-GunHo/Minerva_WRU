import 'package:flutter/material.dart';
import '../core/app_typo.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('연락처', style: AppTypo.body.copyWith(fontWeight: FontWeight.w600))),
      body: const Center(child: Text('연락처 리스트 (추가 예정)')),
    );
  }
}
