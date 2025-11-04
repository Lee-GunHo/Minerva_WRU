import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typo.dart';
import '../data/db.dart';
import 'chat_room_screen.dart';
import '../widgets/chat_tile.dart';   

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController searchC = TextEditingController();
  List<ConversationRow> rows = [];
  List<ConversationRow> filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    searchC.addListener(_onSearch);
  }

  Future<void> _load() async {
    final data = await AppDb().fetchConversations();
    setState(() {
      rows = data;
      filtered = data;
    });
  }

  void _onSearch() {
    final q = searchC.text.trim().toLowerCase();
    setState(() {
      filtered = rows.where((c) =>
        c.title.toLowerCase().contains(q) ||
        c.lastBody.toLowerCase().contains(q)
      ).toList();
    });
  }

  @override
  void dispose() {
    searchC.removeListener(_onSearch);
    searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메시지', style: AppTypo.body.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 🔍 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchC,
              decoration: InputDecoration(
                hintText: '검색 창',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          
          //  대화 리스트
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return ChatTile(
                    item: item,
                    showDivider: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(title: item.title),
                        ),
                      );
                      await _load();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
