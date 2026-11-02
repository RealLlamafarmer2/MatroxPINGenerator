# Matrox PINS Generator

Recreate the **PINS** block of a Matrox Millennium, Mystique, Mystique 220,
Millennium II, G100 or G200 graphics card – for when a bad BIOS flash has
destroyed it and you never saved a backup.

Every Matrox card stores its own configuration (clocks, RAMDAC limits, memory
timing, serial number, board revision) in a 64-byte *PINS* structure inside its
BIOS. If that is lost, Matrox's `PROGBIOS` can rebuild it from a text file:

```
PROGBIOS -i <biosfile>.bin -s MYPINS.TXT -k
```

…but only if you have that text file. This tool generates it from scratch.

## Features

- **38 cards built in**, taken from real `PROGBIOS -d` dumps (see [Credits](#credits)).
- Pick your card type → enter the serial number from its sticker → save.
- Hardware settings are pre-filled with that card's factory values. Where real
  cards of the same family differ, you choose from **only the values those cards
  actually use** (the card's own value is marked `[factory]`).
- Separate field layouts for PINS v1 (Millennium), v2.0/2.1 (Mystique,
  Mystique 220, Millennium II) and v3.0 (G100/G200).
- Expert mode for free editing, with format validation.
- For every built-in card the generator reproduces the original dump's PINS
  lines exactly.

## Download & run

| Platform | File | How to run |
|---|---|---|
| Windows 98 – 11 | [`Windows/PINEDIT.HTA`](Windows/PINEDIT.HTA) | Double-click. No install. (If blocked: right-click → Properties → *Unblock*.) |
| MS-DOS | [`DOS/PINEDIT.BAS`](DOS/PINEDIT.BAS) | `QBASIC /RUN PINEDIT.BAS` (QBasic 1.1, DOS 5–6.22) or compile with QuickBASIC 4.5: `BC PINEDIT; LINK PINEDIT;` |

DOS keys: arrows/PgUp/PgDn move · Enter edits or opens a pick list · F2 save ·
F3 change card · F4 factory reset · F6 expert mode · T today's date · Esc quit.

## Recovering a card

Based on the (archived) Matrox BIOS-recovery guide by Grzegorz Mazur:

1. Fit a second, non-Matrox graphics card, connect the monitor to it, leave the
   Matrox card installed. Boot **plain DOS** (no EMM386, no Windows).
2. Generate `MYPINS.TXT` for your card and copy it next to `PROGBIOS.EXE` and
   the BIOS images (the `MGA\SETUP` folder of the Matrox BIOS package).
3. Run `PROGBIOS -i <biosfile>.bin -s MYPINS.TXT -k`.
   PROGBIOS **1.73** (from `SETUP343`) is recommended – later versions handle
   `-k` badly.
4. Remove the second card and reconnect the monitor.

BIOS file per card (based on SETUP349):

| Card | BIOS file | Card | BIOS file |
|---|---|---|---|
| Millennium | `838-x` | G100 PCI | `873-x` |
| Mystique **and** Mystique 220 PCI | `858-x` | G100 AGP | `874-x` |
| Mystique + Rainbow Runner | `861-x` | old G200 PCI / TV-out | `878-x` / `878-xtvo` |
| Mystique 220 AGP | `866-x` | old G200 AGP / TV-out | `879-x` / `879-xtvo` |
| Millennium II PCI | `859-x` | old G200 AGP / PCI flat panel | `886-x` / `887-x` |
| Millennium II AGP | `865-x` | new G200 PCI (CRT/FP, TV) | `899-x`, `899-xtv` |
| Millennium II PCI / AGP + RR | `876-x` / `877-x` | new G200 AGP (CRT/FP, TV) | `900-x`, `900-xtv` |

## Important notes

- **Field 34 (PINS checksum) is kept from the factory dump.** It also covers
  8 PINS bytes that `PROGBIOS -d` never prints, so it can't be recalculated
  from the text file. The original recovery guide tells users to edit the serial
  and use the file as-is, so PROGBIOS evidently doesn't require it to match.
- Field names for PINS v3 come from the archived *MatroX files* BIOS page; v1/v2
  names from the XFree86 / Linux `matroxfb` drivers. Several fields are
  undocumented and labelled as such.
- **Wrong clock or memory values can stop a card from booting.** When in doubt,
  leave everything at `[factory]` and only enter the serial number.
- **Compaq OEM Mystique 220 (296677-001, board 007414-001):** included, but
  Compaq built its own PCB and its factory ID fields are unknown, so the entry
  uses Matrox Mystique 220 Model 311 values. Clocks match the MGA-1164SG chip.
  See [`examples/`](examples/). A real dump from this card would be very welcome.
- After a corrupted flash, the PCI subsystem vendor ID stored in the BIOS may
  also be wrong. PROGBIOS can patch it: `PROGBIOS -b SUBSYS_VID,2,<low>,<high>`
  (decimal bytes, e.g. Matrox `102B` = `43,16`, Compaq `0E11` = `17,14`).
- No Matrox software or BIOS images are included. Get `PROGBIOS` and BIOS files
  from Matrox's legacy driver archive or a mirror such as vogonsdrivers.com.

**Use at your own risk.** This works with undocumented hardware data; neither the
author nor Matrox is responsible for the result.

## Contributing

The most useful contribution is a **PINS dump from a working card** that isn't
in the list yet – especially OEM (Compaq, Dell, Gateway, IBM…) variants.
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Building from source

The HTA and BAS files are generated – don't edit them directly.

```
cd build
python build.py        # Python 3, no extra packages
```

- `build/pins/` – the PINS dumps (one per card)
- `build/carddb.py` – card list and field definitions for each PINS layout
- `build/pinedit_template.hta`, `build/pinedit_template.bas` – the two front ends

## Credits

- PINS dumps and BIOS documentation: **Grzegorz Mazur**, *MatroX files*
  (grafi.ii.pw.edu.pl/gbm/matrox/, preserved by the Internet Archive), and the
  card owners who sent him their dumps.
- PINS field meanings also from the XFree86 `mga` and Linux `matroxfb` drivers.
- The dump files are third-party data, included unchanged (apart from the added
  Compaq example) for preservation and credited above; the GPL applies to the code.

## License

[GNU General Public License v3.0](LICENSE) – Copyright © 2026 llamafarmer2
