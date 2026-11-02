# Matrox PINS Generator - Copyright (C) 2026 llamafarmer2
# Licensed under the GNU General Public License v3.0 - see LICENSE.
"""Builds the card database used by both the Windows and DOS versions.

Reads the PROGBIOS PINS dumps in ./pins/ and writes cards.json.
To add a card: drop its dump into ./pins/, add a row to CARDS below,
then run build.py.
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))

# file stem, menu group, model label, note, family (cards in a family share option lists)
CARDS = [
    ("MILL",     "Millennium",                         "Millennium (TVP3026, old PINS)", "Old v1 PINS layout", "MILL"),
    ("MYST004",  "Mystique",                           "Model 004",              "",                       "MYST"),
    ("MYST005",  "Mystique",                           "Model 005 (MYST/4I)",    "",                       "MYST"),
    ("MYST006",  "Mystique",                           "Model 006 (MYST/4I)",    "",                       "MYST"),
    ("CPQ296677","Mystique 220",                       "Compaq OEM 296677-001 (board 007414-001)", "Compaq OEM - based on Model 311; ID fields estimated", "M220"),
    ("M220305",  "Mystique 220",                       "Model 305",              "",                       "M220"),
    ("M220308",  "Mystique 220",                       "Model 308",              "PINS v2.0",              "M220"),
    ("M220311",  "Mystique 220",                       "Model 311",              "",                       "M220"),
    ("MIL27030", "Millennium II",                      "Model 004 (703-00 rev.A) PCI", "",                 "MIL2"),
    ("G100100A", "G100",                               "Model 100A (4MB)",       "",                       "G100"),
    ("G1PR101",  "G100",                               "Productiva 8MB, Model 101 (G+/PROA/8BN/5)", "",    "G100"),
    ("G2SD001A", "G200 SD (G2+/SDA)",                  "Model 001A",             "",                       "G200"),
    ("G2SD001B", "G200 SD (G2+/SDA)",                  "Model 001B",             "",                       "G200"),
    ("G2SD001C", "G200 SD (G2+/SDA)",                  "Model 001C",             "",                       "G200"),
    ("G2SD003A", "G200 SD (G2+/SDA)",                  "Model 003A",             "",                       "G200"),
    ("G2SD004",  "G200 SD (G2+/SDA)",                  "Model 004",              "",                       "G200"),
    ("G2SD004C", "G200 SD (G2+/SDA)",                  "Model 004C",             "",                       "G200"),
    ("G2SD005A", "G200 SD (G2+/SDA)",                  "Model 005A",             "",                       "G200"),
    ("G2MS000",  "Millennium G200 SD (G2+/MSDA/8)",    "Model 000",              "250 MHz RAMDAC",         "G200"),
    ("G2MY000A", "Mystique G200 (G2+/MYSA)",           "Model 000A",             "",                       "G200"),
    ("G2MY000B", "Mystique G200 (G2+/MYSA)",           "Model 000B",             "",                       "G200"),
    ("G2MY001C", "Mystique G200 (G2+/MYSA)",           "Model 001C",             "250 MHz RAMDAC",         "G200"),
    ("G2MY002",  "Mystique G200 (G2+/MYSA)",           "Model 002",              "",                       "G200"),
    ("g2my002a", "Mystique G200 (G2+/MYSA)",           "Model 002A",             "250 MHz RAMDAC",         "G200"),
    ("G2MI201",  "Millennium G200 (G2+/MILA)",         "Model 201",              "",                       "G200"),
    ("G2MI202",  "Millennium G200 (G2+/MILA)",         "Model 202",              "",                       "G200"),
    ("G2MI203A", "Millennium G200 (G2+/MILA)",         "Model 203A",             "",                       "G200"),
    ("G2MI205A", "Millennium G200 (G2+/MILA)",         "Model 205A",             "",                       "G200"),
    ("G2MI206",  "Millennium G200 (G2+/MILA)",         "Model 206",              "",                       "G200"),
    ("G2MI206X", "Millennium G200 (G2+/MILA)",         "Model 206 (faster memory)", "",                    "G200"),
    ("G2MI206A", "Millennium G200 (G2+/MILA)",         "Model 206A",             "",                       "G200"),
    ("G2MI207A", "Millennium G200 (G2+/MILA)",         "Model 207A",             "",                       "G200"),
    ("G2MI208",  "Millennium G200 (G2+/MILA)",         "Model 208",              "",                       "G200"),
    ("G2MI209",  "Millennium G200 (G2+/MILA)",         "Model 209",              "",                       "G200"),
    ("G2MI209A", "Millennium G200 (G2+/MILA)",         "Model 209A",             "",                       "G200"),
    ("G2MI209B", "Millennium G200 (G2+/MILA)",         "Model 209B",             "",                       "G200"),
    ("G2MA002A", "Marvel G200",                        "Model 002A (no TV)",     "",                       "G200"),
    ("G2MT003A", "Marvel G200",                        "Model 003A (G200TV)",    "",                       "G200"),
]

# Field classes:
#   fixed - structural, never changes (expert mode can override)
#   card  - identifies this exact board; fixed to the selected card (expert can override)
#   user  - always editable (serial, date, count)
#   hw    - pick from values used by real cards of the same family (expert: free entry)
# Types: text, byte, word, mhz (byte = MHz-100, 255 = default), clk (word, 1/100 MHz),
#        bits, hex8, hex2, date2 (d/m/yy), date4 (d/m/yyyy), serial, pcb ("NNN N")
COMMON_HEAD = [
    ("fixed", "text",   "PIN signature",        "Marks the start of the PIN block."),
    ("fixed", "byte",   "Structure length",     "Size of the PIN block in bytes."),
    ("fixed", "byte",   "Reserved",             "Unused."),
    ("fixed", "text",   "PIN version",          "PIN structure version for this card."),
    ("user",  "DATE",   "Programming date",     "Date the PIN was written."),
    ("user",  "word",   "Programming count",    "How many times the PIN has been programmed."),
    ("card",  "bits",   "Product ID",           "Board product identifier bits."),
    ("user",  "serial", "Serial number",        "From the sticker on your card: 3 capital letters + 5 digits."),
    ("card",  "text",   "Card version",         "Card version from the sticker, e.g. 001B, 205A."),
    ("card",  "pcb",    "PCB number + revision", "Printed on the PCB, e.g. 644 00 (major / minor revision)."),
]

LAYOUT_V2 = COMMON_HEAD + [
    ("hw", "bits", "Feature flags",            "32 feature bits."),
    ("hw", "hex2", "RAMDAC type",              "RAMDAC type code."),
    ("hw", "mhz",  "RAMDAC speed",             "Max RAMDAC speed."),
    ("hw", "mhz",  "Max pixel clock",          "Max pixel clock."),
    ("hw", "mhz",  "Graphics engine clock",    "System / engine PLL."),
    ("hw", "mhz",  "Memory clock",             "Memory clock."),
    ("hw", "mhz",  "Engine clock, 4MB",        "Engine clock used with 4MB memory."),
    ("hw", "mhz",  "Engine clock, 8MB",        "Engine clock used with 8MB memory."),
    ("hw", "byte", "Clock modifier",           "Clock modifier."),
    ("hw", "byte", "Test clock",               "Test clock (255 = default)."),
    ("hw", "byte", "VGA frequency 1",          "Default VGA pixel frequency 1 (255 = default)."),
    ("hw", "byte", "VGA frequency 2",          "Default VGA pixel frequency 2 (255 = default)."),
    ("hw", "bits", "MCTLWTST memory timing",   "Memory controller wait-state bits."),
    ("hw", "bits", "Video control",            "Video control bits."),
    ("hw", "mhz",  "Engine clock, 12MB",       "Engine clock used with 12MB memory."),
    ("hw", "mhz",  "Engine clock, 16MB",       "Engine clock used with 16MB memory."),
] + [("hw", "byte", "Reserved", "Unused (255).")] * 8 + [
    ("fixed", "byte", "PIN checksum",          "Kept from the factory dump; PROGBIOS accepts edited PINS files without changing it."),
]

LAYOUT_V3 = COMMON_HEAD + [
    # Labels from the PInS 3.x table on grafi.ii.pw.edu.pl/gbm/matrox/bios.html
    ("hw", "mhz",  "Max RAMDAC frequency",     "130 = 230 MHz, 150 = 250 MHz."),
    ("hw", "mhz",  "Max pixel clock, 8 bpp",   "Stored as MHz-100."),
    ("hw", "mhz",  "Max pixel clock, 16 bpp",  "Stored as MHz-100."),
    ("hw", "mhz",  "Max pixel clock, 24 bpp",  "Stored as MHz-100."),
    ("hw", "mhz",  "Max pixel clock, 32 bpp",  "Stored as MHz-100."),
    ("hw", "byte", "VGA1 pixel clock",         "255 = default."),
    ("hw", "byte", "VGA2 pixel clock",         "255 = default."),
    ("hw", "byte", "VGA graphics clock",       "Graphics clock in VGA modes, MHz."),
    ("hw", "byte", "2D clock, no mem. expansion", "Graphics clock without memory expansion, MHz."),
    ("hw", "byte", "2D clock, +2MB expansion", "Graphics clock with 2MB memory expansion, MHz."),
    ("hw", "byte", "2D clock, +4MB expansion", "Graphics clock with 4MB memory expansion, MHz."),
    ("hw", "byte", "2D clock, +8MB expansion", "Graphics clock with 8MB memory expansion, MHz."),
    ("hw", "hex8", "Memory control word",      "Memory controller timing (MCTLWTST), hex."),
    ("hw", "byte", "Board options",            "Undocumented option byte."),
    ("hw", "byte", "Video output options",     "Video output options."),
    ("hw", "byte", "Option byte 25",           "Undocumented (memory configuration)."),
    ("hw", "byte", "Option byte 26",           "Undocumented."),
    ("hw", "byte", "Option byte 27",           "Undocumented (memory read-back timing)."),
    ("hw", "byte", "Option byte 28",           "Undocumented (memory read-back timing)."),
    ("hw", "byte", "Option byte 29",           "Undocumented (OPTION2 register)."),
    ("hw", "byte", "Option byte 30",           "Undocumented."),
    ("hw", "byte", "3D graphics clock",        "Graphics clock for 3D, MHz."),
    ("hw", "byte", "Option byte 32",           "Undocumented."),
    ("hw", "byte", "Option byte 33",           "Undocumented."),
    ("fixed", "byte", "PIN checksum",          "Covers 8 hidden PINS bytes PROGBIOS does not dump, so it cannot be recalculated from this file; kept from the factory dump."),
]

LAYOUT_V1 = [
    ("fixed", "byte",   "Structure length",     "Size of the PIN block in bytes."),
    ("card",  "word",   "Product ID",           "Board product identifier."),
    ("user",  "serial", "Serial number",        "From the sticker on your card."),
    ("card",  "DATE",   "Manufacturing date",   "Date the board was made."),
    ("card",  "word",   "Revision ID",          "Board revision."),
    ("card",  "text",   "PCB info",             "PCB information."),
    ("hw",    "word",   "RAMDAC type",          "RAMDAC type code."),
    ("card",  "text",   "Pixel clock limits",   "Pixel clock limits (0 = default)."),
    ("hw",    "word",   "LCLK max",             "0 = default."),
    ("hw",    "word",   "Clock setting 9",      "0 = default."),
    ("hw",    "clk",    "Base clock",           "In 1/100 MHz (5000 = 50.00 MHz)."),
    ("hw",    "clk",    "Clock, 4MB",           "In 1/100 MHz, 0 = default."),
    ("hw",    "clk",    "Clock, 8MB",           "In 1/100 MHz, 0 = default."),
    ("hw",    "word",   "Clock modifier",       "0 = default."),
    ("hw",    "clk",    "Test clock",           "In 1/100 MHz, 0 = default."),
    ("hw",    "clk",    "VGA frequency 1",      "In 1/100 MHz (2517 = 25.17 MHz)."),
    ("hw",    "clk",    "VGA frequency 2",      "In 1/100 MHz (2832 = 28.32 MHz)."),
    ("user",  "DATE",   "Programming date",     "Date the PIN was written."),
    ("user",  "word",   "Programming count",    "How many times the PIN has been programmed."),
    ("hw",    "bits",   "Options",              "32 option bits."),
    ("hw",    "bits",   "Feature flags",        "32 feature bits."),
    ("hw",    "word",   "VGA clock",            "VGA clock setting."),
    ("fixed", "text",   "Structure revision",   "PIN structure revision."),
    ("card",  "word",   "Reserved",             "Unused."),
    ("card",  "word",   "Reserved",             "Unused."),
    ("card",  "word",   "Reserved / check",     "Kept from the factory dump."),
]


def read_dump(path):
    raw = open(path, encoding="latin1", newline="").read()
    lines = raw.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    header, values, trails = [], [], []
    started = False
    for l in lines:
        m = re.match(r"^\s*(\d+): ?(.*)$", l)
        if m:
            started = True
            assert int(m.group(1)) == len(values), (path, l)
            v = m.group(2).rstrip()
            values.append(v)
            trails.append(m.group(2)[len(v):])
        elif not started:
            header.append(l)
    # clean header: start at the Matrox banner, drop warnings, mark VGA enabled
    while header and not header[0].startswith("MGA Bios"):
        header.pop(0)
    header = [h.replace("VGA Disabled", "VGA Enabled") for h in header if "WARNING" not in h]
    if not header or header[-1] != "":
        header.append("")
    return header, values, trails


def build():
    pins_dir = os.path.join(HERE, "pins")
    files = {os.path.splitext(f)[0]: f for f in os.listdir(pins_dir)}
    cards = []
    for stem, group, model, note, fam in CARDS:
        header, values, trails = read_dump(os.path.join(pins_dir, files[stem]))
        if len(values) == 26:
            layout = "v1"
        elif values[3] == "3.0":
            layout = "v3"
        else:
            layout = "v2"
        cards.append(dict(id=stem.upper(), group=group, model=model, note=note, family=fam,
                          layout=layout, header=header, values=values, trails=trails))
    spec = {}
    for name, lay, date in (("v1", LAYOUT_V1, "date4"), ("v2", LAYOUT_V2, "date2"), ("v3", LAYOUT_V3, "date4")):
        spec[name] = [[c, (date if t == "DATE" else t), lbl, desc] for c, t, lbl, desc in lay]
    for c in cards:
        assert len(c["values"]) == len(spec[c["layout"]]), c["id"]
    return {"cards": cards, "layouts": spec}


if __name__ == "__main__":
    db = build()
    json.dump(db, open(os.path.join(HERE, "cards.json"), "w"), indent=1)
    print(len(db["cards"]), "cards")
