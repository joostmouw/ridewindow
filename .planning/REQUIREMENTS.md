# Requirements — Milestone v4.3 Dicht huis

**Defined:** 2026-10-11
**Core Value:** Accurate cyclist-specific weather scoring translated into concrete bookable time slots.
**Milestone goal:** Wat een vreemde met de publieke Supabase-sleutel kan, wordt zichtbaar en begrensd, zonder dat iemand die de app gewoon gebruikt er iets van merkt.
**Bron:** epic #75 in `.planning/BACKLOG.md`. Ontwerp: https://claude.ai/artifact/2iWe1d2BbCanxrTgvsyG9b
**Vorige requirements:** v4.1 staat in `.planning/milestones/v4.1-REQUIREMENTS.md`; v4.2 Clubs in `.planning/workstreams/clubs/REQUIREMENTS.md`.

**Leidend principe:** eerst het gat dat vandaag bestaat, niet het gat dat ooit kan ontstaan. Meten gaat vóór dichttimmeren, en de zwaarste maatregel (captcha, App Check) komt pas als de metingen erom vragen.

**Randvoorwaarden:** €0/maand; alleen plpgsql, geen Edge Functions; uitgelogd blijft alles werken; de anonieme feedbackroute (FB-03) wordt begrensd, nooit geblokkeerd; elke nieuwe functie wordt verantwoord in de migratie die hem toevoegt.

---

## v4.3 Requirements

### Meten (MEET)

- [x] **MEET-01**: Joost ziet per dag, per tabel (`feedback`, `app_events`, maatjes- en groepsuitnodigingen, nieuwe accounts) hoeveel rijen erbij kwamen en van hoeveel verschillende toestellen of accounts
- [x] **MEET-02**: Een dag die ver boven het normale ligt valt op, zonder dat Joost er zelf naar hoeft te zoeken

### Begrenzen (RATE)

- [x] **RATE-01**: `feedback` heeft een plafond per toestel en per afzender per dag; een tester zonder account kan nog steeds feedback sturen *(0016 live 2026-10-12; rate_limits_test.sql checks 2, 4, 5, 6 live groen; probe fase A/B)*
- [x] **RATE-02**: `app_events` heeft een plafond per toestel en per afzender per dag, ruim boven wat de app zelf ooit verstuurt *(checks 7.1-7.3 live groen; probe fase C: 120 aangenomen, 121e geweigerd)*
- [x] **RATE-03**: Een rij in `feedback` of `app_events` kan niet onbeperkt groot zijn: er is een maximale lengte op tekst en op de meegestuurde context *(checks 3.1-3.4 live groen; app_events was al begrensd door 0008)*
- [x] **RATE-04**: Builds die al bij testers en in productie staan vallen onder de grenzen zonder app-update *(PostgREST-probe met de publieke sleutel, vorm van build 70, 2026-10-12 06:37 UTC)*
- [x] **RATE-05**: Een tester boven de feedbackgrens krijgt in de app een duidelijke melding in plaats van een stille fout, en zijn feedback gaat niet verloren *(unit-getest in 38-02; de melding gaat mee met de eerstvolgende build)*

### Uitnodigingscodes (CODE)

- [ ] **CODE-01**: Na vijf mislukte pogingen binnen een uur kan een account tijdelijk geen maatjescode meer inwisselen; de app zegt wanneer het weer kan
- [ ] **CODE-02**: Dezelfde teller geldt voor het inwisselen van een groepslink

### Grenzen per account (GRENS)

- [ ] **GRENS-01**: Eén account kan niet onbeperkt open uitnodigingen, groepsritten en vensteropties aanmaken; de grenzen liggen ver boven normaal gebruik en de app legt uit wat er aan de hand is als je er toch tegenaan loopt

### Accounts (ACCT)

- [ ] **ACCT-01**: Een account dat met e-mail en wachtwoord is aangemaakt werkt pas na bevestiging van het e-mailadres
- [ ] **ACCT-02**: De limieten van Supabase Auth op aanmelden, inlogpogingen en verstuurde mails staan bewust ingesteld en vastgelegd

### Afronden (AFR)

- [ ] **AFR-01**: Het privacybeleid beschrijft wat er voor de begrenzing wordt bijgehouden (zoals een gehasht IP-adres) en hoe lang
- [ ] **AFR-02**: `CLAUDE.md` en `AGENTS.md` noemen de nieuwe plpgsql-functies en waarom de client ze niet kan vervangen
- [ ] **AFR-03**: Regressie groen en een build met de nieuwe meldingen staat bij de testers, via internal en de Oppo

## Future Requirements (deferred)

- **Captcha (Cloudflare Turnstile) op aanmelden of feedback** — pas als MEET laat zien dat begrenzen alleen niet genoeg is
- **App Check / Play Integrity** — raakt elke gebruiker, hoort achteraan
- **Nepaccounts tegenhouden bij zoeken op gebruikersnaam** — wordt pas een vector bij slice 5 van epic #65
- **Route inladen uit Komoot of Strava bij geplande ritten** — volgende epic, na deze milestone (verzoek Joost 2026-10-11)

## Out of Scope

| Feature | Reason |
|---------|--------|
| WAF of Cloudflare vóór Supabase | Kost geld; de €0/maand-grens blijft staan |
| Edge Functions | De constraint is "alleen plpgsql"; alles hier past in triggers en functies |
| Maatregelen die de uitgelogde gebruiker raken | Accounts zijn additief; de app moet zonder account volledig blijven werken |
| De anonieme feedbackroute sluiten | FB-03 eist dat een tester zonder account feedback kan sturen; begrenzen mag, blokkeren niet |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MEET-01 | Phase 37 | Complete |
| MEET-02 | Phase 37 | Complete |
| RATE-01 | Phase 38 | Complete |
| RATE-02 | Phase 38 | Complete |
| RATE-03 | Phase 38 | Complete |
| RATE-04 | Phase 38 | Complete |
| RATE-05 | Phase 38 | Complete |
| CODE-01 | Phase 39 | Pending |
| CODE-02 | Phase 39 | Pending |
| GRENS-01 | Phase 39 | Pending |
| ACCT-01 | Phase 40 | Pending |
| ACCT-02 | Phase 40 | Pending |
| AFR-01 | Phase 40 | Pending |
| AFR-02 | Phase 40 | Pending |
| AFR-03 | Phase 40 | Pending |

**Coverage:**
- v4.3 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-10-11*
*Last updated: 2026-10-11 after roadmap v4.3 (fases 37–40)*
