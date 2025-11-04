import 'package:flutter/material.dart';
import '../core/app_typo.dart';
import '../core/app_colors.dart';

class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});
  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  // ===== 사이즈/간격 튜닝 포인트 =====
  static const double _cellHeight = 56;       // 각 셀(격자 칸) 높이
  static const double _mainSpacing = 8;       // 행 간격
  static const double _crossSpacing = 8;      // 열 간격
  static const double _gridPadV = 6;          // GridView 위/아래 패딩
  static const double _btnWidthFactor = 0.78; // 버튼 가로 (셀 대비 비율)
  static const double _btnHeightFactor = 0.78;// 버튼 세로 (셀 대비 비율)

  final digits = ['1','2','3','4','5','6','7','8','9','*','0','#'];
  String input = '';
  final searchC = TextEditingController();

  void onDigit(String d) {
    setState(() {
      input = (input + d).trim();
      searchC.text = input;
      searchC.selection = TextSelection.fromPosition(
        TextPosition(offset: searchC.text.length),
      );
    });
  }

  void onBackspace() {
    setState(() {
      if (input.isNotEmpty) {
        input = input.substring(0, input.length - 1);
        searchC.text = input;
        searchC.selection = TextSelection.fromPosition(
          TextPosition(offset: searchC.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3열 × 4행(12개) 기준 그리드 총 높이 계산
    const rows = 4;
    final gridHeight =
        (_cellHeight * rows) + (_mainSpacing * (rows - 1)) + (_gridPadV * 2);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('전화', style: AppTypo.body.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // 🔍 검색창
              TextField(
                controller: searchC,
                onChanged: (v) => setState(() => input = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  hintText: "연락처 또는 번호 검색",
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 번호 표시
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: double.infinity,
                child: Text(
                  input.isEmpty ? '번호 입력' : input,
                  textAlign: TextAlign.center,
                  style: AppTypo.title.copyWith(letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 12),

              // 다이얼 버튼 그리드 (작은 흰색 버튼 + 누를 때만 반짝)
              SizedBox(
                height: gridHeight, // 전체 그리드 높이 제한
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: _gridPadV),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: _mainSpacing,
                    crossAxisSpacing: _crossSpacing,
                    mainAxisExtent: _cellHeight, // 각 셀 높이 고정
                  ),
                  itemCount: digits.length,
                  itemBuilder: (_, i) {
                    final d = digits[i];
                    return Center(
                      child: FractionallySizedBox(
                        widthFactor: _btnWidthFactor,
                        heightFactor: _btnHeightFactor,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,               // 항상 흰색
                            foregroundColor: AppColors.textPrimary,      // 텍스트 색
                            elevation: 0,                                 // 그림자 제거
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border), // 옅은 테두리
                            ),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                          ).merge(
                            ButtonStyle(
                              // 누를 때만 살짝 반짝(리플 오버레이)
                              overlayColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return AppColors.primary.withOpacity(0.12); // 0.08~0.16 조절
                                }
                                return null; // 기본값(리플 없음)
                              }),
                            ),
                          ),
                          onPressed: () => onDigit(d),
                          child: Text(d, style: AppTypo.title),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // 하단 액션
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onBackspace,
                    icon: const Icon(Icons.backspace_outlined),
                    tooltip: '지우기',
                  ),
                  const SizedBox(width: 32),
                  Material(
                    color: const Color(0xFF10B981),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('통화 시도: $input')),
                        );
                      },
                      child: const SizedBox(
                        width: 64, height: 64,
                        child: Icon(Icons.call, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
