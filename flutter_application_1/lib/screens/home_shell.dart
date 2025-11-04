import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'dialpad_screen.dart';
import 'recent_screen.dart';
import 'main_screen.dart';
import 'contacts_screen.dart';
import 'messages_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    DialPadScreen(),
    RecentScreen(),
    MainScreen(),
    ContactsScreen(),
    MessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),

      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => index = 0), // 통화 FAB → 키패드 탭
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        child: const Icon(Icons.call),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar:MediaQuery( // ✅ 시스템 글자크기 확대 무시(바 영역만)
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child:SafeArea( 
        top:false,
        child:BottomAppBar(
        height: 60,
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Tab(icon: Icons.dialpad,  label: '키패드',    selected: index == 0, onTap: () => setState(() => index = 0)),
            _Tab(icon: Icons.history,  label: '최근기록',  selected: index == 1, onTap: () => setState(() => index = 1)),
            const SizedBox(width: 48), // FAB 자리
            _Tab(icon: Icons.contacts, label: '연락처',    selected: index == 3, onTap: () => setState(() => index = 3)),
            _Tab(icon: Icons.message,  label: '메시지',    selected: index == 4, onTap: () => setState(() => index = 4)),
          ],
        ),
      ),
      ),
    )
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return SizedBox(              // ✅ 탭 자체 높이 고정
      height: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ 중앙 정렬
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),        // ✅ 아이콘 살짝 축소
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 10,                           // ✅ 글자 크기 축소
                height: 1.0,                            // ✅ 줄간격(ascender/descender) 억제
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
