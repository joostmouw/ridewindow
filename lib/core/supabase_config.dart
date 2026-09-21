// lib/core/supabase_config.dart
//
// Supabase-project URL + anon key. Deze anon key is publiek van ontwerp:
// hij zit sowieso leesbaar in elke APK en elke webbundel — een JWT decoder
// legt hem in seconden bloot, ongeacht waar in de codebase hij staat. Niet
// de geheimhouding van deze sleutel beschermt de data, maar Postgres
// row-level security (RLS), die in Fase 21 op elke tabel wordt gezet.
// "Fix" dit later dus niet door de sleutel naar --dart-define of .env te
// verplaatsen (D-14) — dat vergroot alleen het risico dat één vergeten
// build-vlag stilzwijgend een build oplevert waarin inloggen kapot is.
// Zelfde afweging als D-13/D-19 in 18-CONTEXT.md voor de keep-warm-job's
// anon key.
const supabaseUrl = 'https://hcdrydlgqpnmumfupgcx.supabase.co';
const supabaseAnonKey =
    '****************************************************************************************************************************************************************************************************************';

/// Waarheen Supabase de browser stuurt na het bevestigen van een e-mailadres
/// (open.md punt 11, 2026-09-21). Op Android opent dit schema de app; de SDK
/// verwerkt de code in de URL zelf (SupabaseAuth, detectSessionInUri staat
/// standaard aan). De URL moet in het dashboard staan bij Authentication,
/// URL Configuration, Additional Redirect URLs (`ridewindow://**`), anders
/// valt de bevestigingsmail terug op de Site URL: een dood localhost-adres
/// op een toestel.
///
/// Op web wordt bewust géén emailRedirectTo meegegeven: een custom schema
/// bestaat daar niet, dus de browser-flow (landen op de PWA) blijft staan.
const kEmailConfirmRedirect = 'ridewindow://confirm';
