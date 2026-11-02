# Contributing

## Send a PINS dump (most helpful!)

If you have a **working** Matrox card that isn't in the card list, or any OEM
variant (Compaq, Dell, Gateway, IBM, HP, Siemens…), please share its PINS:

1. Boot plain DOS and go to the folder with `PROGBIOS.EXE` and `DOS4GW.EXE`.
2. Run:
   ```
   PROGBIOS -d >MYPINS.TXT
   ```
   This only **reads** the BIOS – it doesn't change anything.
3. Open an issue (or a pull request adding the file to `build/pins/`) with:
   - the `MYPINS.TXT` file,
   - the card name and all sticker / PCB markings (e.g. `G2+/MILA/8D`,
     `Model 203A`, `798-02`, OEM part numbers),
   - the chip marking (e.g. `MGA-1164SG`).

The serial number in the dump is your card's sticker serial. You may replace it
with `ABC12345` if you prefer – it isn't needed.

## Adding a card yourself

1. Put the dump in `build/pins/` (8.3 file name, e.g. `G2MI210.TXT`).
2. Add a row to `CARDS` in `build/carddb.py`. Cards with the same *family*
   share drop-down options, so use the right one (`MYST`, `M220`, `MIL2`,
   `G100`, `G200`, …).
3. Run `python build.py` in `build/` and commit the regenerated
   `Windows/PINEDIT.HTA` and `DOS/PINEDIT.BAS`.

## Code changes

Edit the templates in `build/`, never the generated files. Keep the Windows
version ES3 JavaScript (no `let`, arrow functions, etc.) so it still runs on
Windows 98's script engine. Keep the DOS version QBasic 1.1 compatible.
