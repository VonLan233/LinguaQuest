import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/repositories/profile_repository.dart';
import 'package:linguaquest/features/profile/public_profile_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// A repository whose [getPublicProfile] always throws the supplied error.
class _ThrowingProfileRepository implements ProfileRepository {
  _ThrowingProfileRepository(this._error);

  final Object _error;

  @override
  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    throw _error;
  }
}

Widget _harness(Object error) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(
        _ThrowingProfileRepository(error),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const PublicProfileScreen(userId: 'ghost-user'),
    ),
  );
}

DioException _notFound() => DioException(
      requestOptions: RequestOptions(path: '/users/ghost-user/profile'),
      response: Response(
        requestOptions: RequestOptions(path: '/users/ghost-user/profile'),
        statusCode: 404,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  group('PublicProfileScreen error states', () {
    testWidgets('404 shows a friendly not-found empty state, not raw exception',
        (tester) async {
      await tester.pumpWidget(_harness(_notFound()));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.publicProfileNotFoundTitle), findsOneWidget);
      expect(find.text(l10n.publicProfileNotFoundMessage), findsOneWidget);

      // Must NOT leak exception internals onto the screen.
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('Could not load profile'), findsNothing);
      expect(find.textContaining('404'), findsNothing);
    });

    testWidgets('non-404 error shows a generic load-failed state',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          DioException(
            requestOptions: RequestOptions(path: '/users/x/profile'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.publicProfileLoadFailedTitle), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('Could not load profile'), findsNothing);
    });
  });
}
