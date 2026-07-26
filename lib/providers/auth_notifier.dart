// lib/providers/auth_notifier.dart
// authStateProvider: enige bron van waarheid voor "wie is ingelogd".
// Gegenereerde providernamen: authStateProvider, currentUserIdProvider.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_notifier.g.dart';

/// Streamt de ingelogde Supabase-gebruiker.
///
/// `keepAlive: true` omdat elke latere provider die reageert op in-/uitloggen
/// (Fase 20's repositories) hierop leunt en nooit mag disposen tussen
/// listener-drops door.
///
/// Twee Supabase-valkuilen (ARCHITECTURE.md §1) waar deze implementatie
/// expliciet omheen bouwt:
/// 1. De herstelde sessie is direct na `Supabase.initialize()` synchroon
///    beschikbaar via `currentSession` — maar de daaropvolgende stream,
///    `onAuthStateChange`, herhaalt géén synchrone beginwaarde zoals
///    Firebase's `authStateChanges()` dat wel doet. Zonder deze seed toont
///    een koude start één frame lang "uitgelogd" (AUTH-04 zou dan flaky
///    zijn, niet waar).
/// 2. `User.id` is een Supabase-UUID, geen Google-account-id. AUTH-07's
///    Calendar-mismatch-vergelijking (Plan 19-05) moet `.email` gebruiken,
///    niet dit id.
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) async* {
  // Seed: de herstelde sessie is al beschikbaar zodra Supabase.initialize()
  // is afgerond -- dit moet vóór onAuthStateChange komen, anders mist de
  // eerste frame de al-ingelogde staat.
  yield Supabase.instance.client.auth.currentSession?.user;
  yield* Supabase.instance.client.auth.onAuthStateChange.map(
    (state) => state.session?.user,
  );
}

/// Afgeleide waarde voor callsites die alleen het id nodig hebben.
/// Retourneert null tijdens het laden en wanneer uitgelogd.
///
/// Let op: dit is de Supabase-UUID (`auth.users.id`), niet het Google-
/// account-id -- zie de waarschuwing hierboven bij [authState].
@riverpod
String? currentUserId(Ref ref) => ref.watch(authStateProvider).value?.id;
