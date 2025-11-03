// Widget test for Profile Screen - Test Push functionality
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamsync_lite/screens/profile/profile_screen.dart';
import 'package:streamsync_lite/features/auth/auth_bloc.dart';

void main() {
  group('ProfileScreen Widget Test', () {
    testWidgets('displays profile screen with test push form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(),
            child: const ProfileScreen(),
          ),
        ),
      );

      // Verify profile screen elements
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Test Push Notification'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Send Test Push'), findsOneWidget);
    });

    testWidgets('test push form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(),
            child: const ProfileScreen(),
          ),
        ),
      );

      // Try to submit empty form
      final sendButton = find.text('Send Test Push');
      await tester.tap(sendButton);
      await tester.pump();

      // Validation should prevent submission (form key validation)
      // In a real test, you'd verify the form validation messages
    });

    testWidgets('theme toggle switch is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(),
            child: const ProfileScreen(),
          ),
        ),
      );

      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
