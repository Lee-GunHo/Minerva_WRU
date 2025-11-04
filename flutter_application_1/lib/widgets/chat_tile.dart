import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typo.dart';
import '../data/db.dart'; // ConversationRow 모델용

class ChatTile extends StatelessWidget {
  final ConversationRow item;
  final VoidCallback onTap;
  final bool showDivider; // 하단 구분선 표시 여부 (옵션)

  const ChatTile({
    super.key,
    required this.item,
    required this.onTap,
    this.showDivider = false,
  });

  String _fmtTime(int ms) {
    if (ms == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final ap = dt.hour >= 12 ? '오후' : '오전';
    final h = ((dt.hour + 11) % 12) + 1;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ap $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _fmtTime(item.lastTimeMs);
    final titleStyle = AppTypo.body.copyWith(
      fontWeight: item.unread > 0 ? FontWeight.w700 : FontWeight.w500,
    );

    return Column(
      children: [
        ListTile(
          tileColor: Colors.white,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          //  왼쪽 프로필 아이콘
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(.12),
            child: Text(
              item.title.characters.first,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),

          //  이름 + 마지막 메시지
          title: Text(
            item.title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.lastBody,
            style: AppTypo.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // 시간 + 읽지 않음 뱃지
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeText,
                style: AppTypo.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (item.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.unread}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 선택적으로 Divider 추가
        if (showDivider)
          const Divider(height: 1, color: AppColors.border, thickness: 0.8),
      ],
    );
  }
}
