---
phase: 19-auth
plan: 07
status: complete
completed: 2026-09-07
requirements: [AUTH-10, REG-01, REG-02, REG-04]
---

# 19-07 — Regressiechecklist ingevuld

## Wat er gebeurd is

Dit plan was het enige handwerk van fase 19: een mens moest een Play-installatie doorlopen, een
iPhone-PWA doorlopen en een koudestart meten. Het werk is grotendeels **wel gedaan maar nooit
vastgelegd** — de Play-verificatie vond plaats op 2026-09-02 (toestelsessie 10) tijdens fase 21, en
bleef sindsdien als los feit in het geheugen en in `MANUAL-VERIFICATION-21.md` hangen in plaats van
in de checklist waar hij hoorde. Daardoor stond fase 19 zeven maanden op 6/7 terwijl er inhoudelijk
nauwelijks iets ontbrak.

`REGRESSION-CHECKLIST.md` is nu ingevuld: **10 van de 15 vinkjes afgetekend, elk met de bron van de
observatie erbij**, en 5 open met de reden.

## Wat is afgetekend

**Android release vanaf Play (5/5).** Opstarten, inloggen zonder `ApiException: 10`, Calendar lezen
én schrijven, uitloggen met behoud van de agenda-koppeling, en "Synced" die een koude start
overleeft. Dit is AUTH-10 en het telt alleen vanaf een Play-installatie, omdat Google met een eigen
sleutel hertekent — in dit project is Calendar precies daarop al eens stukgegaan terwijl de sideload
werkte. Bron: toestelsessie 10, 2026-09-02.

**Koudestartmeting (5/5), gedaan op 2026-09-07.** `domContentLoaded` 287 ms, `loadEvent` 1637 ms,
`main.dart.js` 989 kB overgedragen. Gemeten via de Navigation Timing API in de live PWA, op desktop
Chrome over vast breedband, direct na een deploy en met `no-cache`-headers, dus geen warme cache.

Twee dingen zijn bewust anders dan het sjabloon voorschreef, en allebei staan ze in het bestand
zelf: de meting is op desktop gedaan en niet op een telefoon (op het toestel antwoordt Chrome's
DevTools-socket niet, dus daar was alleen een stopwatch mogelijk), en `paint`/LCP zijn niet
gerapporteerd omdat Flutter in een canvas tekent en die entries daar leeg blijven. **Dit getal is
geen toets van §4's 2-secondengrens** — `loadEvent` valt vóór het tekenen van de eerste slot-kaart.
Het is een reproduceerbare bovengrens voor de laadkant.

## Wat open blijft, en waarom

**De hele iPhone-sectie (5 vinkjes).** Er is geen iPhone in het project; het testtoestel is een
Oppo. Dat is een grens aan wat waarneembaar is, niet een vergeten stap.

Indirect weten we wél iets: een tester met een iPhone meldde op 2026-09-06 (met screenshot, nu
backlog #63) dat hij via Profiel → "Edit my schedule" op het beschikbaarheidsscherm kwam en daar
niet terug kon behalve met een veeg. Dat bewijst dat installeren, openen en navigeren tot op zekere
hoogte werken — en levert meteen een defect op dat op Android onzichtbaar is. Te weinig om vinkjes
op te zetten, genoeg om te weten dat het pad bestaat.

**Hoe dit dichtgaat:** vraag dezelfde tester de vijf stappen te doorlopen. Goedkoper dan een toestel
kopen, en hij heeft #63 al gemeld.

## Wat dit betekent voor de fase

Fase 19 is hiermee 7/7. De enige inhoudelijke schuld die overblijft is iOS-verificatie, en die is
niet oplosbaar met de middelen van dit project — hij hoort thuis bij de tester, niet bij een plan.
