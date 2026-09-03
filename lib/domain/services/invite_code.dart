import 'dart:math';

/// Alfabet voor uitnodigingscodes.
///
/// Bewust zonder `0`/`O`, `1`/`I`/`L` en `U`/`V`: een code belandt niet alleen
/// in een link maar wordt ook voorgelezen door de telefoon of overgetypt van
/// een scherm. Kleine letters ontbreken om dezelfde reden — dan hoeft niemand
/// zich af te vragen of hoofdlettergevoeligheid meespeelt.
const kInviteCodeAlphabet = 'ABCDEFGHJKMNPQRSTWXYZ23456789';

/// Lengte van een uitnodigingscode.
///
/// Met 29 tekens geeft 8 posities ongeveer 5·10^11 mogelijkheden. De code is de
/// enige beveiliging op een uitnodiging (zie `0002_peloton.sql`, keuze 1), dus
/// dit getal is geen cosmetische keuze: korter maakt raden haalbaar, langer
/// maakt overtypen vervelend.
const kInviteCodeLength = 8;

/// Genereert een uitnodigingscode.
///
/// [random] is injecteerbaar zodat een test een vaste reeks kan geven; de
/// productie-default is [Random.secure]. Dat laatste is niet vrijblijvend —
/// `Random()` zonder seed is voorspelbaar genoeg om codes te raden zodra je er
/// een paar gezien hebt, en dit is precies het soort detail dat in een review
/// wegvalt omdat beide varianten er identiek uitzien.
String generateInviteCode({Random? random}) {
  final rnd = random ?? Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < kInviteCodeLength; i++) {
    buffer.write(kInviteCodeAlphabet[rnd.nextInt(kInviteCodeAlphabet.length)]);
  }
  return buffer.toString();
}

/// Maakt een door de gebruiker ingetypte code vergelijkbaar met een
/// gegenereerde: hoofdletters, geen spaties of streepjes.
///
/// Mensen plakken een hele link in het codeveld of typen `ABCD-EFGH`. Dat is
/// geen fout van de gebruiker maar van het veld, dus het wordt hier opgevangen
/// in plaats van met een foutmelding beantwoord.
String normalizeInviteCode(String input) {
  final trimmed = input.trim();
  // Een geplakte link: neem wat er achter de laatste '/' of '=' staat.
  final lastSeparator =
      max(trimmed.lastIndexOf('/'), trimmed.lastIndexOf('='));
  final tail =
      lastSeparator >= 0 ? trimmed.substring(lastSeparator + 1) : trimmed;
  return tail.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
