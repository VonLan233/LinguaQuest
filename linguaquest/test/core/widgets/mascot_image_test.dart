import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/mascot_image.dart';

void main() {
  testWidgets('MascotImage loads the cat asset at requested size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MascotImage(size: 64)),
      ),
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(MascotImage),
        matching: find.byType(Image),
      ),
    );
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'lib/assets/image/icon.png');
    expect(image.width, 64);
  });
}
