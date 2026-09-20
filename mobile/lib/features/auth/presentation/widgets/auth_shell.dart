import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

/// Layout auth : fond marque [brand_header_v2.png] + feuille surface arrondie.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerHeightFactor = 0.34,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double headerHeightFactor;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerH = size.height * headerHeightFactor;
    final topPad = MediaQuery.paddingOf(context).top;
    final sheet = ThemeTokens.of(context).surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: sheet,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerH + 40,
              child: ColoredBox(
                color: AppColors.primary,
                child: Image.asset(
                  'assets/images/brand_header_v2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const SizedBox.expand(),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textOnPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: math.max(
                      headerH - topPad - (onBack != null ? 48 : 16),
                      120,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _BrandMark(),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textOnPrimary
                                      .withValues(alpha: 0.88),
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: sheet,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fidel',
      child: SvgPicture.asset(
        'assets/images/logo_mark_white.svg',
        width: 168,
        height: 52,
        fit: BoxFit.contain,
        // flutter_svg ignore souvent les <style> CSS → sans ça le fill tombe en noir.
        colorFilter: const ColorFilter.mode(
          AppColors.textOnPrimary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
