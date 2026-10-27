import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/app.dart';

void main() {
  testWidgets('app starts in Arabic, right-to-left', (tester) async {
    await tester.pumpWidget(const KidsEnglishApp());
    await tester.pump();
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.rtl);
  });
}
