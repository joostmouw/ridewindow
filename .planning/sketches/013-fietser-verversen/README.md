# Schets 013 — de fietser bij het verversen

**Vraag (Joost, 2026-09-10):** laat het fietsende mannetje uit de intro vaker terugkomen — bij
omlaag trekken om te verversen fietst hij in volle vaart binnen, op de plek van het laadrondje,
en vervangt dat.

**Drie standen naast elkaar** in `index.html`:

- **Nu** — het Material-rondje van `RefreshIndicator` (Home en Peloton).
- **A · Hij komt binnenfietsen** — na loslaten van links naar het midden, trapt door tijdens het
  laden, rijdt rechts weg als het klaar is.
- **B · Trekken is trappen** — de fietser volgt je vinger; hoe verder je trekt, hoe verder hij
  fietst en hoe harder de wielen draaien. Voorbij de drempel loslaten = verversen.

**Wat gemeten is, niet aangenomen:** de bron `assets/animations/welcome_ride.webp` (206 frames)
bevat **geen trapbeweging**. De beweging tussen opeenvolgende frames zakt vanaf frame ~167 naar
nul; wat overblijft is een langzame verschuiving omhoog. De fietser aan het eind is een
stilstaand plaatje.

**Wat de mockup daarom doet:** `rider.png` is frame 205, uitgeknipt en met de achtergrond
omgezet naar transparantie (luminantie → alfa, inkt in `brandDark`). Draaiende spaken zijn
eroverheen getekend op de gemeten wielmiddelpunten (70, 260) en (284, 260), straal ~46 in
`rider.png`-pixels. Daarbij een lichte op-en-neer en snelheidsstreepjes. Echte trappende benen
vragen de tekening in lagen — route (b) uit backlog #52.

**Bestanden:** `contact.png` (elk 9e frame), `grid.png`
(het raster waarmee de wielen zijn gelokaliseerd), `rider.png`, `home.png` (winkel-screenshot
als achtergrond).

**Openen:** `python3 -m http.server 8765` vanuit de repo-root, dan
`http://localhost:8765/.planning/sketches/013-fietser-verversen/`.
