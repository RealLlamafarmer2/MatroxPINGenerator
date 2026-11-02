# Matrox PINS Generator - Copyright (C) 2026 llamafarmer2
# Licensed under the GNU General Public License v3.0 - see LICENSE.
"""Generates Windows\\PINEDIT.HTA and DOS\\PINEDIT.BAS from the card database.
Usage:  python build.py
"""
import json, os
from carddb import build, HERE

ROOT = os.path.dirname(HERE)
LAYNUM = {"v1": 1, "v2": 2, "v3": 3}


def trails_code(trails):
    out = ""
    for t in trails:
        assert t == " " * len(t) and len(t) < 10, repr(t)
        out += str(len(t))
    return out


def q(s):
    assert '"' not in s, s
    return '"' + s + '"'


def main():
    db = build()
    for c in db["cards"]:
        c["trails"] = trails_code(c["trails"])
        assert len(c["header"]) == 6 and c["header"][3].startswith("Matrox"), c["id"]

    # ---- Windows HTA ----
    js_db = {"layouts": db["layouts"],
             "cards": [{k: c[k] for k in ("id", "group", "model", "note", "family", "layout", "header", "values", "trails")}
                       for c in db["cards"]]}
    hta = open(os.path.join(HERE, "pinedit_template.hta"), encoding="cp1252").read()
    hta = hta.replace("/*DB*/", json.dumps(js_db, separators=(",", ":")))
    os.makedirs(os.path.join(ROOT, "Windows"), exist_ok=True)
    open(os.path.join(ROOT, "Windows", "PINEDIT.HTA"), "w", encoding="cp1252", newline="\r\n").write(hta)

    # ---- DOS QBasic ----
    d = ["' ---- Field layouts: count, then class, type, label, description ----", "LayoutData:"]
    for name in ("v1", "v2", "v3"):
        lay = db["layouts"][name]
        d.append("DATA %d" % len(lay))
        for f in lay:
            d.append("DATA " + ",".join(q(x) for x in f))
    d.append("")
    d.append("' ---- Cards: id, group, model, note, family, layout, trailing spaces, header count, header lines, values ----")
    d.append("CardData:")
    d.append("DATA %d" % len(db["cards"]))
    for c in db["cards"]:
        d.append("' " + c["id"])
        d.append("DATA " + ",".join([q(c["id"]), q(c["group"]), q(c["model"]), q(c["note"]), q(c["family"]),
                                      str(LAYNUM[c["layout"]]), q(c["trails"]), str(len(c["header"]))]))
        d.append("DATA " + ",".join(q(h) for h in c["header"]))
        vals = [q(v) for v in c["values"]]
        for k in range(0, len(vals), 12):
            d.append("DATA " + ",".join(vals[k:k + 12]))
    bas = open(os.path.join(HERE, "pinedit_template.bas")).read().replace("{{DATA}}", "\n".join(d))
    for line in bas.split("\n"):
        assert len(line) < 250, line
    os.makedirs(os.path.join(ROOT, "DOS"), exist_ok=True)
    open(os.path.join(ROOT, "DOS", "PINEDIT.BAS"), "w", encoding="ascii", newline="\r\n").write(bas)
    print("built", len(db["cards"]), "cards")


if __name__ == "__main__":
    main()
