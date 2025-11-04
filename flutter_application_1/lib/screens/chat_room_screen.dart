import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typo.dart';

class ChatRoomScreen extends StatefulWidget {
  final String title;
  const ChatRoomScreen({super.key, this.title = '누나'});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final controller = TextEditingController();
  final scrollC = ScrollController();

  // 더미 메시지 (type: text / sticker / card)
  final List<Msg> msgs = [
    Msg(time: '오후 8:38', text: '커피사머거', isMe: false),
    Msg(time: '오후 8:41', text: '고맙소', isMe: true, tint: const Color(0xFFF3DFA6)),
    Msg(time: '오후 8:41', type: MsgType.card, text: '송금봉투를 받았어요.\n\n*(안내) 페이앱에 출석만 하면 받을 수 있는 포인트가 있어요.',
        isMe: false),
    Msg(time: '오후 8:41', text: '오킹', isMe: false),
    Msg(date: '2025년 10월 23일 목요일'),
    Msg(time: '오후 6:47', text: 'ㅋㅋ', isMe: false),
    Msg(time: '오후 8:41', text: '구래 바보야', isMe: false),
    Msg(time: '오후 8:41', text: '누나가 준 용돈으로 커피사먹',
        isMe: true, tint: const Color(0xFFF3DFA6)),
  ];

  @override
  void dispose() {
    controller.dispose();
    scrollC.dispose();
    super.dispose();
  }

  void _send() {
    final t = controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      msgs.add(Msg(time: _nowHm(), text: t, isMe: true, tint: const Color(0xFFF3DFA6)));
    });
    controller.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (scrollC.hasClients) {
        scrollC.animateTo(
        scrollC.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 앱바 (뒤로가기, 제목, 검색/더보기)
      appBar: AppBar(
        title: Text(widget.title, style: AppTypo.body.copyWith(fontWeight: FontWeight.w700)),
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 12),
          Icon(Icons.menu),
          SizedBox(width: 8),
        ],
      ),

      // 배경 + 채팅 리스트 + 입력바
      body: Stack(
        children: [
          const _SoftHeartsBackground(),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollC,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];

                    // 날짜 칩
                    if (m.date != null) {
                      return _DateChip(label: m.date!);
                    }

                    // 스티커(간단 예: 큰 이모지)
                    if (m.type == MsgType.sticker) {
                      return _StickerBubble(isMe: m.isMe, emoji: '🐻', time: m.time);
                    }

                    // 카드형 알림
                    if (m.type == MsgType.card) {
                      return _CardBubble(isMe: m.isMe, text: m.text ?? '', time: m.time);
                    }

                    // 기본 텍스트 말풍선
                    return _ChatBubble(
                      isMe: m.isMe,
                      text: m.text ?? '',
                      time: m.time,
                      tint: m.tint, // 노란 말풍선 등
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              _InputBar(
                controller: controller,
                onSend: _send,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nowHm() {
    final now = TimeOfDay.now();
    final h = now.hour;
    final mm = now.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? '오후' : '오전';
    final hh = ((h + 11) % 12 + 1).toString();
    return '$ap $hh:$mm';
  }
}

/* ---------- 배경: 연한 하트 아이콘을 흩뿌려서 느낌만 ---------- */
class _SoftHeartsBackground extends StatelessWidget {
  const _SoftHeartsBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeartsPainter(),
      child: Container(color: Colors.transparent),
    );
  }
}

class _HeartsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF6EE7B7).withOpacity(0.15);
    final hearts = [
      const Offset(40, 80), const Offset(200, 60),
      const Offset(120, 260), const Offset(300, 200),
      const Offset(70, 420), const Offset(280, 520),
    ];
    for (final o in hearts) {
      _drawHeart(canvas, o, 18, paint);
      // 부드러운 glow
      final glow = Paint()..color = paint.color.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      _drawHeart(canvas, o, 10, glow);
    }
  }

  void _drawHeart(Canvas c, Offset o, double s, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..cubicTo(o.dx - s, o.dy - s, o.dx - s * 1.2, o.dy + s * 0.6, o.dx, o.dy + s)
      ..cubicTo(o.dx + s * 1.2, o.dy + s * 0.6, o.dx + s, o.dy - s, o.dx, o.dy);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ---------- 날짜 칩 ---------- */
class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppTypo.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- 텍스트 말풍선 ---------- */
class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String? time;
  final Color? tint; // 내 메시지 배경색 등

  const _ChatBubble({
    required this.isMe,
    required this.text,
    this.time,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? (isMe ? const Color(0xFFECECEC) : Colors.white);
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                // 보낸 사람 아바타(옵션)
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('assets/images/sample_avatar.png'), // 없으면 에러→ 주석 처리 가능
                  // backgroundColor: Colors.transparent,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: radius,
                    border: Border.all(color: AppColors.border, width: 0.6),
                  ),
                  child: Text(
                    text,
                    style: AppTypo.body.copyWith(height: 1.35),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (time != null)
                Text(time!, style: AppTypo.caption.copyWith(color: AppColors.textSecondary)),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------- 카드형 알림 ---------- */
class _CardBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String? time;
  const _CardBubble({required this.isMe, required this.text, this.time});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTypo.body.copyWith(height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: const Text('내역보기')),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('포인트 받기')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('카카오페이', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          )
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: 8, bottom: 8, left: isMe ? 60 : 8, right: isMe ? 8 : 60,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 40),
          card,
          const SizedBox(width: 6),
          if (time != null)
            Text(time!, style: AppTypo.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/* ---------- 스티커 ---------- */
class _StickerBubble extends StatelessWidget {
  final bool isMe;
  final String emoji;
  final String? time;
  const _StickerBubble({required this.isMe, required this.emoji, this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8, bottom: 8, left: isMe ? 120 : 8, right: isMe ? 8 : 120,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(width: 8),
          if (time != null)
            Text(time!, style: AppTypo.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/* ---------- 하단 입력바 ---------- */
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '메시지 입력',
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions_outlined)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const SizedBox(
                width: 44, height: 44,
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- 모델 ---------- */
enum MsgType { text, sticker, card }

class Msg {
  final bool isMe;
  final String? text;
  final String? time;
  final String? date;   // 날짜 칩 표시용
  final MsgType type;
  final Color? tint;    // 말풍선 배경 커스텀

  Msg({
    this.isMe = false,
    this.text,
    this.time,
    this.date,
    this.type = MsgType.text,
    this.tint,
  });
}
