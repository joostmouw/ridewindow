# Promotiemateriaal

Schermafdrukken en beeldmateriaal om Ridewindow mee aan te prijzen. Gemaakt op
2026-09-21 op de Oppo Find X9 Pro, build 1.0.35 (46), lichte modus.

```
docs/promo/
├── nl/   Nederlandse app-taal
├── en/   Engelse app-taal
└── home-1.0.35.jpg   losse Home-afdruk voor de wervingsposts van fase 27
```

Beide mapjes bevatten dezelfde vijf schermen, plus het logo, de feature-graphic
en het introductiefilmpje.

| Bestand | Wat erop staat |
|---|---|
| `01-home.png` | Home: dagstrip, geplande rit, en de beste kaart met score en weerbalken |
| `02-rit-detail.png` / `02-ride-detail.png` | Ritdetail: tijd aanpassen, weer, daglicht, kledingadvies |
| `03-agenda.png` | De weekagenda |
| `04-ritten.png` / `04-rides.png` | Het rittenoverzicht |
| `05-profiel.png` / `05-profile.png` | Profiel, **uitgelogd** |
| `logo-512.png` | Het app-icoon, 512x512, hetzelfde bestand als op de winkelpagina |
| `feature-graphic.png` | De feature-graphic van de winkelpagina |
| `intro.mp4` | De login-animatie, versie zonder watermerk |

## Twee dingen om te weten voor je ze gebruikt

**Profiel staat er uitgelogd op, en dat is opzet.** Ingelogd toont dat scherm
een mailadres, en dat hoort niet in materiaal dat je rondstuurt. Uitgelogd laat
het bovendien zien wat een nieuwe gebruiker ziet, wat voor promotie eerlijker is.

**Home toont een echte week met echte data.** De datums (21 tot en met 27
september) en de geplande rit op maandag verouderen. Wil je een tijdloze afdruk,
maak dan een nieuwe wanneer de week er gunstig uitziet; een rij met louter groene
dagen verkoopt beter dan een rij met regen.

## De filmpjes

In `photos/` staan vier mp4's, waarvan drie varianten van dezelfde
login-animatie: gewoon, zonder watermerk, en "special edition". **Joost koos op
2026-09-21 de versie zonder watermerk**, na ze naast elkaar te hebben gezien:
dat is het beste filmpje. Die staat hier als `intro.mp4`; de andere twee
blijven in `photos/` en hoeven niet opnieuw beoordeeld te worden.

`photos/*.mp4` staat in `.gitignore` en die keuze is hier aangehouden: de
`intro.mp4` in deze mapjes wordt niet meegecommit. De repo is openbaar en tien
megabyte videobestand hoort daar niet in. Wil je ze er toch in, haal dan de regel
`docs/promo/*/intro.mp4` uit `.gitignore` weg.
