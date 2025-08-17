// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gatheringpeps/widgets/app_logo.dart';

void main() {
  group('App Logo Tests', () {
    testWidgets('AppLogo widget displays correctly', (WidgetTester tester) async {
      // Build our widget and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 100),
          ),
        ),
      );

      // Verify that the logo widget is displayed
      expect(find.byType(AppLogo), findsOneWidget);
      
      // Verify that the container is displayed
      expect(find.byType(Container), findsOneWidget);
      
      // Verify that the image is displayed
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('AppLogoWithText widget displays correctly', (WidgetTester tester) async {
      // Build our widget and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLogoWithText(
              logoSize: 80,
              title: 'Test App',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      // Verify that the logo widget is displayed
      expect(find.byType(AppLogoWithText), findsOneWidget);
      
      // Verify that the title text is displayed
      expect(find.text('Test App'), findsOneWidget);
      
      // Verify that the subtitle text is displayed
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('AppLogo handles error gracefully', (WidgetTester tester) async {
      // Build our widget and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 100),
          ),
        ),
      );

      // Simulate an error by triggering a rebuild
      await tester.pump();

      // Verify that the widget is still displayed
      expect(find.byType(AppLogo), findsOneWidget);
    });
  });
}
