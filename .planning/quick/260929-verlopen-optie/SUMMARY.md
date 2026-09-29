---
quick_id: 260929-verlopen-optie
date: 2026-09-29
status: complete (lokaal gecommit, nog niet in een build)
---

# Een venster dat al voorbij is, staat niet meer ter keuze

## Wat er gebouwd is (4b8b42b)

- `GroupRide.openOptions({now})`: de vensters die nog niet begonnen zijn.
  `hasOpenChoice` en `frontRunner` rekenen daarmee.
- De rittenlijst (`_OptionsBlock`: lijst, volgorde en "jij hebt overal
  gestemd") en het ritdetail (`_buildOptionVoters`) tonen alleen die.
- Tests: model (voorbij en al begonnen tellen niet; twee toekomstige naast een
  verlopen blijven een keuze; een stem en een 100 op een verlopen venster
  maken het geen koploper), de ritkaart, en het detail.

## Vondsten

1. **Elke testoptie lag in de toekomst** (`DateTime.now()` + dagen), dus geen
   test kon dit zien. Het werd pas zichtbaar toen een echte rit een venster
   voorlegde dat twee dagen later voorbij was.
2. **Bij Richards rit verdwijnt het blok helemaal.** Van zijn twee vensters
   (zo 27 sep, di 29 sep) blijft er één over, en dat is de rit zelf; volgens
   de bestaande regel "één venster is geen keuze" staat er dan niets meer te
   kiezen.
3. **"Al begonnen" telt als voorbij**, niet pas "afgelopen": op een venster
   dat loopt nog stemmen of het als eigenaar kiezen, verandert niets meer.
4. **De detailtest bewijst zichzelf.** Met alleen de fix in het ritdetail
   teruggedraaid faalt hij op "Anna, Mark" (de stemmen op het verlopen
   venster); met de fix slaagt hij. Een eerste poging die ook het model
   terugdraaide, faalde op compilatie en bewees dus niets.

## Bewust niet aangeraakt

- De opties blijven in de database staan: geen server-side opschoning (alleen
  `plpgsql` mag, en dit is weergave, geen gegevensfout).
- Het voorstelscherm (`invite_buddies_sheet`) biedt alleen vensters uit de
  komende dagen aan; daar kan geen verlopen venster in.
