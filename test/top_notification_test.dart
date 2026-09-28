import 'package:downloader_all_platform/shared/widgets/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TopNotification displays at top and dismisses', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TopNotification.show(
                    context,
                    message: 'Download started!',
                    actionLabel: 'VIEW',
                    onAction: () {},
                  );
                },
                child: const Text('Show Notification'),
              );
            },
          ),
        ),
      ),
    );

    // Initial state: not visible
    expect(find.text('Download started!'), findsNothing);

    // Tap to show
    await tester.tap(find.text('Show Notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Visible on screen
    expect(find.text('Download started!'), findsOneWidget);
    expect(find.text('VIEW'), findsOneWidget);

    // Test dismissal
    TopNotification.dismiss();
    await tester.pumpAndSettle();

    expect(find.text('Download started!'), findsNothing);
  });
}
