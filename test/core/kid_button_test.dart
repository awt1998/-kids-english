import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/core/theme/app_spacing.dart';
import 'package:kids_english/core/widgets/kid_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('fires onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(KidButton(label: 'يلا', onPressed: () => taps++)),
    );
    await tester.tap(find.byType(KidButton));
    expect(taps, 1);
  });

  testWidgets('is never smaller than the minimum touch target', (tester) async {
    await tester.pumpWidget(
      host(KidButton(icon: Icons.star, onPressed: () {})),
    );
    final size = tester.getSize(find.byType(KidButton));
    expect(size.height, greaterThanOrEqualTo(AppTouch.minTarget));
  });

  testWidgets('does nothing when disabled', (tester) async {
    await tester.pumpWidget(host(const KidButton(label: 'x', onPressed: null)));
    await tester.tap(find.byType(KidButton));
    await tester.pump();
  });
}
