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
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjZHJ5ZGxncXBubXVtZnVwZ2N4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5ODkxNTUsImV4cCI6MjEwMDU2NTE1NX0.X2XcNbotlY0u_UV5R633FVRLnXvabFVNgisbGOZIifo';
