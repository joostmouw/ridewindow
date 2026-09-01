"""Meet de koude start van de RideWindow-PWA op een Android-toestel via adb.

REG-03 stelt dat het eerste ride slot binnen 2 seconden na de tik zichtbaar moet zijn.
Dit script meet dat niet als één getal maar als een verdeling: per run wordt op een
exact tijdstip na de tik één screenshot genomen en geclassificeerd. Draai je meerdere
offsets, dan krijg je een curve ("op 2,0s zichtbaar in 9 van de 12 starts") in plaats
van een enkele meting die toevallig meezit of tegenzit.

Gebruik:
    python3 tools/measure_cold_start.py                       # standaardcurve
    python3 tools/measure_cold_start.py --offsets 1.9 2.0 --runs 8
    python3 tools/measure_cold_start.py --list-webapks        # pakketnaam opzoeken

Eerste meting: 2026-09-01, zie .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md
(device session 8). Mediaan lag toen op ~1,75-1,8s.

DRIE DINGEN DIE EERDER STIL EEN VERKEERD GETAL OPLEVERDEN
---------------------------------------------------------
1. `screenrecord` werkt niet op de PLG110 -- "Permission denied", ook naar
   /data/local/tmp waar shell wél mag schrijven. Het is policy, geen padprobleem.
   `screencap` mag daar wel schrijven; vandaar deze opzet.

2. Android's **task snapshot**. Tijdens de launch-animatie toont Android een screenshot
   van hoe de app er bij het afsluiten uitzag -- een scherm vol ride-kaarten. Een naïeve
   detector ziet die aan voor een echte render en meet 0,06s. `am force-stop` wist die
   snapshot niet. Sample daarom nooit vóór ~1,5s, of eis de volgorde
   snapshot -> leeg/spinner -> inhoud.

3. Tijdstempels op de host. Een `adb shell`-aanroep kost ~0,5s round trip; zit die in je
   meting, dan is het getal net zoveel te pessimistisch. Alle tijdstempels hier komen
   daarom van `date +%s.%N` óp het toestel, direct vóór `input tap` en vóór `screencap`.

DE DETECTOR IS EEN PIXELHEURISTIEK, GEEN OORDEEL
------------------------------------------------
"Eerste ride slot" = het aandeel bijna-witte pixels in de middenzone springt van ~0%
naar ~84%, omdat de ride-kaart een lichte kaart op een groene achtergrond is. Verandert
het ontwerp van Home, dan moet LIGHT_THRESHOLD of de crop mee. Controleer bij twijfel
een frame met het blote oog -- het script bewaart ze in --keep-dir.
"""
import argparse
import os
import subprocess
import sys
import time

from PIL import Image

ADB = os.path.expanduser("~/Library/Android/sdk/platform-tools/adb")

# De geïnstalleerde PWA (WebAPK). Opzoeken met --list-webapks; het pakket verandert
# zodra de PWA opnieuw geïnstalleerd wordt.
WEBAPK = "org.chromium.webapk.a5a380363e216c9c6_v2"
CHROME = "com.android.chrome"

# Coördinaten op de PLG110 (1272x2772), app-lade geopend en naar R gesprongen.
# Het PWA-icoon staat níet op pagina 1 van het beginscherm.
ICON = ("1074", "1444")
LETTER_R = ("1247", "1540")
DRAWER_SWIPE = ("636", "2500", "636", "900", "300")

# `input tap` heeft zelf ~50ms nodig ná de tijdstempel; het script corrigeert daarvoor
# en rapporteert altijd het werkelijk gemeten tijdstip, niet het bedoelde.
TAP_LATENCY = 0.05

LIGHT_THRESHOLD = 0.5   # aandeel lichte pixels waarboven een ride-kaart staat
CROP = (0.10, 0.35, 0.90, 0.55)   # links, boven, rechts, onder (fractie van het scherm)


def adb(*args):
    return subprocess.run([ADB] + list(args), capture_output=True, text=True)


def light_fraction(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    box = im.crop((int(w * CROP[0]), int(h * CROP[1]), int(w * CROP[2]), int(h * CROP[3])))
    px = list(box.getdata())
    return sum(1 for r, g, b in px if r > 235 and g > 240 and b > 235) / len(px)


def list_webapks():
    out = adb("shell", "pm", "list", "packages").stdout
    for line in out.splitlines():
        pkg = line.replace("package:", "").strip()
        if "webapk" not in pkg:
            continue
        dump = adb("shell", "dumpsys", "package", pkg).stdout
        marker = "my-project-joost.web.app" if "my-project-joost.web.app" in dump else ""
        print(f"{pkg}  {marker}")


def one_run(offset, keep_dir, index):
    """Eén koude start; geeft (werkelijk gemeten offset, slot zichtbaar) terug."""
    # De WebAPK draait in Chrome's proces -- allebei stoppen, anders is het geen koude start.
    adb("shell", "am", "force-stop", CHROME)
    adb("shell", "am", "force-stop", WEBAPK)
    adb("shell", "input", "keyevent", "KEYCODE_HOME")
    time.sleep(1.0)
    adb("shell", "input", "swipe", *DRAWER_SWIPE)
    time.sleep(1.6)
    adb("shell", "input", "tap", *LETTER_R)
    time.sleep(1.6)

    adb("shell",
        f"cd /data/local/tmp && rm -f one.png t*.txt && date +%s.%N > tap.txt && "
        f"input tap {ICON[0]} {ICON[1]} && sleep {offset - TAP_LATENCY:.3f} && "
        f"date +%s.%N > tcap.txt && screencap -p one.png")

    shot = os.path.join(keep_dir, f"t{offset:.2f}_run{index}.png") if keep_dir else "/tmp/one.png"
    adb("pull", "/data/local/tmp/tap.txt", "/tmp/tap.txt")
    adb("pull", "/data/local/tmp/tcap.txt", "/tmp/tcap.txt")
    adb("pull", "/data/local/tmp/one.png", shot)

    measured = float(open("/tmp/tcap.txt").read()) - float(open("/tmp/tap.txt").read())
    return measured, light_fraction(shot)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--offsets", type=float, nargs="+", default=[1.5, 1.75, 2.0, 2.25],
                    help="tijdstippen na de tik waarop gesampled wordt (seconden)")
    ap.add_argument("--runs", type=int, default=6, help="starts per tijdstip")
    ap.add_argument("--keep-dir", default=None, help="map om de frames te bewaren")
    ap.add_argument("--list-webapks", action="store_true", help="toon WebAPK-pakketten en stop")
    args = ap.parse_args()

    if args.list_webapks:
        list_webapks()
        return 0

    if not adb("shell", "true").returncode == 0:
        print("Geen toestel bereikbaar via adb.", file=sys.stderr)
        return 1
    if args.keep_dir:
        os.makedirs(args.keep_dir, exist_ok=True)
    if min(args.offsets) < 1.4:
        print("Let op: onder ~1,5s kan Android's task snapshot een vals positief geven "
              "-- zie de kop van dit bestand.", file=sys.stderr)

    summary = []
    for offset in args.offsets:
        hits = []
        for k in range(args.runs):
            measured, frac = one_run(offset, args.keep_dir, k)
            visible = frac > LIGHT_THRESHOLD
            hits.append((measured, visible))
            print(f"  {offset:.2f}s bedoeld / {measured:.3f}s gemeten  "
                  f"slot={'JA ' if visible else 'nee'}  (licht {frac * 100:.0f}%)")
        n = sum(1 for _, v in hits if v)
        avg = sum(m for m, _ in hits) / len(hits)
        summary.append((avg, n, len(hits)))

    print("\nverdeling:")
    for avg, n, total in summary:
        print(f"  op {avg:.2f}s: zichtbaar in {n}/{total} starts")
    print("\nREG-03 vraagt <2s. Rapporteer de verdeling, niet één getal -- de spreiding "
          "tussen starts is groter dan je zou willen.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
