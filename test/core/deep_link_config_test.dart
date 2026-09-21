import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/core/supabase_config.dart';

/// Houdt de deep-link-redirect van de e-mailbevestiging in vorm.
///
/// De constante moet voldoen aan wat drie partijen ervan verwachten:
/// - Supabase (dashboard, Additional Redirect URLs) matcht het schema;
/// - Android opent de app op dat schema via het intent-filter in
///   AndroidManifest.xml (bewaakt door manifest_well_formed_test.dart);
/// - de SDK (SupabaseAuth) verwerkt de code in de URL zelf.
///
/// Dit is bewust één kleine test: de echte eis is dat schema, manifest en
/// dashboard dezelfde naam gebruiken, en de manifest-kant zit al in de
/// structuurtest.
void main() {
  test('kEmailConfirmRedirect is een ridewindow-deep-link die de bevestiging '
      'identificeert', () {
    final uri = Uri.parse(kEmailConfirmRedirect);

    expect(uri.scheme, 'ridewindow');
    // `ridewindow://confirm`: Android matcht het intent-filter op het schema,
    // en `confirm` (hier de host van de URI) onderscheidt deze redirect van
    // eventuele andere deep links op hetzelfde schema. De SDK kijkt alleen
    // naar de query-parameters (de code), dus de host is een vrije keuze.
    expect(uri.host, 'confirm');
  });

  test(
      'kEmailConfirmRedirect begint met het schema dat de manifest declareert',
      () {
    // De structuurtest kijkt naar het <data android:scheme>-attribuut; deze
    // test legt de verbinding naar de constante die signUp meestuurt.
    expect(kEmailConfirmRedirect.startsWith('ridewindow://'), isTrue);
  });
}
