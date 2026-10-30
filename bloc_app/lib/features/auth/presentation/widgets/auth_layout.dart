import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final form = SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 40 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: child,
                ),
              ),
            );
            return Row(
              children: [
                if (wide)
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                      ),
                      child: const Center(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.hub_rounded,
                                color: AppColors.accent,
                                size: 48,
                              ),
                              SizedBox(height: 40),
                              Text(
                                'Một nơi kết nối.\nCùng nhau tiến xa.',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Cập nhật thông tin, chia sẻ ý kiến và giữ kết nối với đồng nghiệp mỗi ngày.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  height: 1.6,
                                ),
                              ),
                              SizedBox(height: 32),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  Chip(label: Text('Thông tin tập trung')),
                                  Chip(label: Text('Trao đổi thuận tiện')),
                                ],
                              ),
                              SizedBox(height: 40),
                              Text(
                                'COMMUNITY BOARD · TRUYỀN THÔNG NỘI BỘ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(child: form),
              ],
            );
          },
        ),
      ),
    ),
  );
}
