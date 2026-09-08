#!/usr/bin/env python3
"""Draait een geanimeerde WebP achterstevoren om.

Anders dan `webp_speed.py` kan dit niet zonder hercoderen. In
`welcome_ride.webp` is maar een vijfde van de frames een volledig beeld; de
rest is een deltaatje op een uitsnede, bovenop zijn voorganger geblend. De
chunkvolgorde omdraaien levert daarom onzin op — elk deltaatje mist dan het
beeld waar het bij hoort.

Het script stelt daarom eerst elke frame tot een volledig beeld samen, keert de
rij om, en codeert opnieuw. Standaard **lossless**, zodat er in die ronde geen
scherpte verloren gaat; dat kost bestandsgrootte maar geen kwaliteit. Met
`--quality N` kies je in plaats daarvan lossy.

    python3 tool/webp_reverse.py bron.webp doel.webp [--ms 42] [--quality 90]

`--ms` zet de framelengte van het resultaat (standaard: die van de bron).
"""
import sys

from PIL import Image, ImageSequence


def main(argv: list[str]) -> int:
    args: list[str] = []
    opts: dict[str, str] = {}
    it = iter(argv[1:])
    for a in it:
        if a.startswith("--"):
            value = next(it, None)
            if value is None:
                print(f"{a} mist een waarde.")
                return 64
            opts[a[2:]] = value
        else:
            args.append(a)
    if len(args) != 2:
        print(__doc__)
        return 64
    src, dst = args

    with Image.open(src) as im:
        frames = [f.convert("RGBA") for f in ImageSequence.Iterator(im)]
        source_ms = im.info.get("duration", 42)
        loop = im.info.get("loop", 1)

    if not frames:
        print(f"{src} bevat geen frames.")
        return 65

    ms = int(opts.get("ms") or source_ms)
    frames.reverse()

    save_kwargs = dict(
        save_all=True,
        append_images=frames[1:],
        duration=ms,
        loop=loop,
        minimize_size=True,
    )
    if "quality" in opts:
        save_kwargs.update(lossless=False, quality=int(opts["quality"]), method=6)
    else:
        save_kwargs.update(lossless=True, method=4)

    frames[0].save(dst, **save_kwargs)
    print(
        f"{len(frames)} frames omgekeerd  "
        f"{ms} ms per frame  "
        f"{len(frames) * ms} ms totaal  "
        f"→ {dst}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
