' ============================================================
'  Matrox PINS Generator - Copyright (C) 2026 llamafarmer2
'  GPL-3.0 - https://www.gnu.org/licenses/gpl-3.0.html
'  PINEDIT.BAS - Matrox PIN file generator for MS-DOS
'  Pick your card, enter its serial number, adjust settings,
'  and save a PINS file for:  PROGBIOS -i <bios>.bin -s MYPINS.TXT -k
'
'  Runs in QBasic 1.1 (MS-DOS 5/6):   QBASIC /RUN PINEDIT.BAS
'  Or compile with QuickBASIC 4.5:     BC PINEDIT; LINK PINEDIT;
'  Card data generated from real PROGBIOS dumps - do not hand-edit DATA.
' ============================================================
DEFINT A-Z

DECLARE SUB LoadDB ()
DECLARE SUB PickCard ()
DECLARE SUB ResetCard (ser$)
DECLARE FUNCTION CurSerial$ ()
DECLARE SUB DrawEditor ()
DECLARE SUB EditField ()
DECLARE SUB SaveFile ()
DECLARE SUB Fill (r, t$)
DECLARE SUB BuildOptions (i)
DECLARE FUNCTION PickOption$ (i, r)
DECLARE FUNCTION GetKey$ ()
DECLARE FUNCTION EditLine$ (r, c, w, init$, maxLen)
DECLARE FUNCTION AskYN (q$)
DECLARE FUNCTION Validate$ (i, v$)
DECLARE FUNCTION CheckDate$ (v$, four)
DECLARE FUNCTION NormDate$ (v$)
DECLARE FUNCTION IsDigits (s$)
DECLARE FUNCTION BitsOK (s$)
DECLARE FUNCTION Hint$ (t$, v$)
DECLARE FUNCTION Today$ (t$)
DECLARE FUNCTION CardTitle$ (k)
DECLARE FUNCTION FirstError$ ()

CONST MAXC = 60
CONST MAXH = 8
CONST MAXO = 40
CONST LISTTOP = 4
CONST VIS = 15

' layouts (1=v1, 2=v2, 3=v3): field count + per-field class, type, label, description
DIM SHARED LNum(3), SCls$(3, 35), STyp$(3, 35), SLab$(3, 35), SDsc$(3, 35)
' cards
DIM SHARED NCards
DIM SHARED CId$(MAXC), CGrp$(MAXC), CMod$(MAXC), CNote$(MAXC), CFam$(MAXC), CLay(MAXC), CTrl$(MAXC)
DIM SHARED CNH(MAXC), CHdr$(MAXC, MAXH), CVal$(MAXC, 35)
' current state
DIM SHARED Cur, NF, V$(35), Sel, Top, Expert, Msg$, EditOK, FileErr, SaveName$
DIM SHARED Opt$(MAXO), NOpt

ON ERROR GOTO ErrHandler
LoadDB
SaveName$ = "MYPINS.TXT"
Cur = 0
COLOR 7, 1: CLS: LOCATE , , 0
PickCard
IF Cur = 0 THEN COLOR 7, 0: CLS: END
ResetCard ""

DO
  DrawEditor
  k$ = GetKey$
  Msg$ = ""
  IF LEN(k$) = 2 THEN
    SELECT CASE RIGHT$(k$, 1)
      CASE "H": IF Sel > 0 THEN Sel = Sel - 1
      CASE "P": IF Sel < NF - 1 THEN Sel = Sel + 1
      CASE "I": Sel = Sel - VIS: IF Sel < 0 THEN Sel = 0
      CASE "Q": Sel = Sel + VIS: IF Sel > NF - 1 THEN Sel = NF - 1
      CASE "G": Sel = 0
      CASE "O": Sel = NF - 1
      CASE "<": SaveFile
      CASE "="
        old = Cur: s$ = CurSerial$
        PickCard
        IF Cur = 0 THEN Cur = old ELSE ResetCard s$
      CASE ">"
        IF AskYN("Reset all values to this card's factory dump? (Y/N)") THEN ResetCard CurSerial$: Msg$ = "Factory values restored (serial kept)"
      CASE "@"
        IF Expert THEN
          Expert = 0: Msg$ = "Expert mode OFF"
        ELSEIF AskYN("Expert mode allows ANY value in every field. Wrong values can brick the card. Enable? (Y/N)") THEN
          Expert = -1: Msg$ = "Expert mode ON - all fields editable"
        END IF
    END SELECT
  ELSE
    SELECT CASE ASC(k$)
      CASE 13: EditField
      CASE 27
        IF AskYN("Quit PIN generator? (Y/N)") THEN EXIT DO
      CASE ELSE
        t$ = STyp$(CLay(Cur), Sel)
        IF UCASE$(k$) = "T" AND (t$ = "date2" OR t$ = "date4") AND (SCls$(CLay(Cur), Sel) = "user" OR Expert) THEN V$(Sel) = Today$(t$)
    END SELECT
  END IF
  IF Sel < Top THEN Top = Sel
  IF Sel > Top + VIS - 1 THEN Top = Sel - VIS + 1
LOOP
COLOR 7, 0: CLS
END

ErrHandler:
  FileErr = ERR
  RESUME NEXT

{{DATA}}

FUNCTION AskYN (q$)
  COLOR 15, 4: Fill 22, " " + q$
  DO
    k$ = UCASE$(GetKey$)
  LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
  AskYN = (k$ = "Y")
END FUNCTION

FUNCTION BitsOK (s$)
  BitsOK = 0
  IF LEN(s$) < 4 OR (LEN(s$) MOD 5) <> 4 THEN EXIT FUNCTION
  FOR k = 1 TO LEN(s$)
    c$ = MID$(s$, k, 1)
    IF k MOD 5 = 0 THEN
      IF c$ <> " " THEN EXIT FUNCTION
    ELSE
      IF c$ <> "0" AND c$ <> "1" THEN EXIT FUNCTION
    END IF
  NEXT k
  BitsOK = -1
END FUNCTION

SUB BuildOptions (i)
  ' distinct values of field i among cards of the same family and layout
  NOpt = 0
  L = CLay(Cur)
  IF SCls$(L, i) <> "hw" THEN NOpt = 1: Opt$(1) = CVal$(Cur, i): EXIT SUB
  FOR k = 1 TO NCards
    IF CFam$(k) = CFam$(Cur) AND CLay(k) = L THEN
      found = 0
      FOR j = 1 TO NOpt
        IF Opt$(j) = CVal$(k, i) THEN found = -1
      NEXT j
      IF NOT found AND NOpt < MAXO THEN NOpt = NOpt + 1: Opt$(NOpt) = CVal$(k, i)
    END IF
  NEXT k
  ' sort (numeric when both are numbers)
  FOR a = 1 TO NOpt - 1
    FOR b = a + 1 TO NOpt
      sw = 0
      IF IsDigits(Opt$(a)) AND IsDigits(Opt$(b)) THEN
        IF VAL(Opt$(a)) > VAL(Opt$(b)) THEN sw = -1
      ELSEIF Opt$(a) > Opt$(b) THEN
        sw = -1
      END IF
      IF sw THEN SWAP Opt$(a), Opt$(b)
    NEXT b
  NEXT a
END SUB

FUNCTION CardTitle$ (k)
  t$ = CGrp$(k) + " - " + CMod$(k)
  IF CNote$(k) <> "" THEN t$ = t$ + " (" + CNote$(k) + ")"
  CardTitle$ = t$
END FUNCTION

FUNCTION CheckDate$ (v$, four)
  CheckDate$ = ""
  p1 = INSTR(v$, "/"): IF p1 = 0 THEN GOTO BadDate
  p2 = INSTR(p1 + 1, v$, "/"): IF p2 = 0 THEN GOTO BadDate
  d$ = LEFT$(v$, p1 - 1): m$ = MID$(v$, p1 + 1, p2 - p1 - 1): y$ = MID$(v$, p2 + 1)
  IF NOT IsDigits(d$) OR NOT IsDigits(m$) OR NOT IsDigits(y$) THEN GOTO BadDate
  IF LEN(d$) > 2 OR LEN(m$) > 2 THEN GOTO BadDate
  IF four AND LEN(y$) <> 4 THEN GOTO BadDate
  IF NOT four AND LEN(y$) <> 2 THEN GOTO BadDate
  d = VAL(d$): m = VAL(m$)
  IF d < 1 OR d > 31 OR m < 1 OR m > 12 THEN CheckDate$ = "Invalid day or month": EXIT FUNCTION
  IF four THEN
    IF VAL(y$) < 1990 OR VAL(y$) > 2099 THEN CheckDate$ = "Year must be 1990-2099"
  END IF
  EXIT FUNCTION
BadDate:
  IF four THEN CheckDate$ = "Use D/M/YYYY" ELSE CheckDate$ = "Use D/M/YY"
END FUNCTION

SUB DrawEditor
  L = CLay(Cur)
  t$ = " Matrox PIN Generator  |  " + CardTitle$(Cur)
  IF Expert THEN t$ = t$ + "  [EXPERT]"
  COLOR 0, 7: Fill 1, t$
  COLOR 14, 1: Fill 2, " " + CHdr$(Cur, 4) + "  |  " + LTRIM$(RTRIM$(CHdr$(Cur, 5))) + "  |  family: " + CFam$(Cur)
  COLOR 11, 1: Fill 3, "  #  Parameter                Value                     Info"

  FOR r = 0 TO VIS - 1
    i = Top + r
    IF i > NF - 1 THEN
      COLOR 7, 1: Fill LISTTOP + r, ""
    ELSE
      e$ = Validate$(i, V$(i))
      IF STyp$(L, i) = "serial" AND V$(i) = "" THEN e$ = "required"
      mark$ = " "
      IF e$ <> "" THEN
        mark$ = "!"
      ELSEIF V$(i) <> CVal$(Cur, i) AND SCls$(L, i) <> "user" THEN
        mark$ = "*"
      END IF
      c$ = SCls$(L, i)
      tag$ = ""
      IF c$ = "user" THEN
        tag$ = "<- enter"
      ELSEIF c$ = "hw" THEN
        BuildOptions i
        IF NOpt > 1 THEN tag$ = LTRIM$(STR$(NOpt)) + " choices" ELSE tag$ = "fixed"
      ELSE
        tag$ = "fixed"
      END IF
      h$ = Hint$(STyp$(L, i), V$(i))
      IF h$ <> "" THEN tag$ = h$ + " " + tag$
      l$ = RIGHT$("   " + LTRIM$(STR$(i)), 3) + "  " + LEFT$(SLab$(L, i) + SPACE$(24), 24) + " " + LEFT$(V$(i) + SPACE$(25), 25) + mark$ + " " + tag$
      IF i = Sel THEN
        COLOR 0, 3
      ELSEIF mark$ = "!" THEN
        COLOR 12, 1
      ELSEIF mark$ = "*" THEN
        COLOR 15, 1
      ELSEIF c$ = "user" THEN
        COLOR 10, 1
      ELSE
        COLOR 7, 1
      END IF
      Fill LISTTOP + r, l$
    END IF
  NEXT r

  COLOR 8, 1: Fill 19, STRING$(79, 196)
  COLOR 14, 1: Fill 20, " " + SLab$(L, Sel) + ": " + SDsc$(L, Sel)
  e$ = Validate$(Sel, V$(Sel))
  IF STyp$(L, Sel) = "serial" AND V$(Sel) = "" THEN e$ = "Required - type the serial number from your card's sticker"
  IF e$ <> "" THEN
    COLOR 12, 1: Fill 21, " INVALID: " + e$
  ELSEIF V$(Sel) <> CVal$(Cur, Sel) AND SCls$(L, Sel) <> "user" THEN
    COLOR 15, 1: Fill 21, " * Not this card's factory value (factory: " + CVal$(Cur, Sel) + ")"
  ELSE
    COLOR 11, 1: Fill 21, ""
  END IF
  IF Msg$ <> "" THEN COLOR 15, 4 ELSE COLOR 7, 1
  Fill 22, " " + Msg$
  COLOR 0, 7
  Fill 23, " Enter=Edit/Choose  F2=Save  F3=Change card  F4=Factory reset  F6=Expert  Esc=Quit"
  Fill 24, " Green = fill these in   T = today's date   * = changed from factory   ! = invalid"
END SUB

SUB EditField
  L = CLay(Cur): i = Sel
  c$ = SCls$(L, i): t$ = STyp$(L, i)
  r = LISTTOP + (Sel - Top)
  IF c$ <> "user" AND NOT Expert THEN
    BuildOptions i
    IF NOpt <= 1 THEN
      IF c$ = "hw" THEN Msg$ = "Every card of this type uses this value." ELSE Msg$ = "Fixed for this card (F6 = expert mode to override)."
      EXIT SUB
    END IF
    nv$ = PickOption$(i, r)
    IF EditOK THEN V$(i) = nv$
    EXIT SUB
  END IF
  cur$ = V$(i)
  DO
    COLOR 14, 1: Fill 22, " Type the new value.  Enter=OK  Esc=Cancel"
    nv$ = LTRIM$(RTRIM$(EditLine$(r, 31, 42, cur$, 40)))
    IF NOT EditOK THEN EXIT SUB
    IF t$ = "serial" AND NOT Expert THEN nv$ = UCASE$(nv$)
    IF t$ = "date2" OR t$ = "date4" THEN nv$ = NormDate$(nv$)
    e$ = Validate$(i, nv$)
    IF e$ = "" THEN V$(i) = nv$: EXIT SUB
    COLOR 15, 4: Fill 21, " INVALID: " + e$ + " - fix it or press Esc"
    cur$ = nv$
  LOOP
END SUB

FUNCTION EditLine$ (r, c, w, init$, maxLen)
  s$ = init$: p = LEN(s$) + 1
  IF maxLen > w - 1 THEN maxLen = w - 1
  DO
    LOCATE r, c: COLOR 0, 7: PRINT LEFT$(s$ + SPACE$(w), w);
    LOCATE r, c + p - 1, 1
    k$ = GetKey$
    IF LEN(k$) = 2 THEN
      SELECT CASE RIGHT$(k$, 1)
        CASE "K": IF p > 1 THEN p = p - 1
        CASE "M": IF p <= LEN(s$) THEN p = p + 1
        CASE "G": p = 1
        CASE "O": p = LEN(s$) + 1
        CASE "S": IF p <= LEN(s$) THEN s$ = LEFT$(s$, p - 1) + MID$(s$, p + 1)
      END SELECT
    ELSE
      a = ASC(k$)
      IF a = 13 THEN EditOK = -1: EXIT DO
      IF a = 27 THEN EditOK = 0: EXIT DO
      IF a = 8 AND p > 1 THEN s$ = LEFT$(s$, p - 2) + MID$(s$, p): p = p - 1
      IF a >= 32 AND a <= 126 AND LEN(s$) < maxLen THEN s$ = LEFT$(s$, p - 1) + k$ + MID$(s$, p): p = p + 1
    END IF
  LOOP
  LOCATE , , 0
  EditLine$ = s$
END FUNCTION

SUB Fill (r, t$)
  LOCATE r, 1: PRINT LEFT$(t$ + SPACE$(79), 79);
END SUB

FUNCTION FirstError$
  FirstError$ = ""
  L = CLay(Cur)
  FOR i = 0 TO NF - 1
    e$ = Validate$(i, V$(i))
    IF STyp$(L, i) = "serial" AND V$(i) = "" THEN e$ = "required (from the card's sticker)"
    IF e$ <> "" THEN FirstError$ = "Field" + STR$(i) + " (" + SLab$(L, i) + "): " + e$: EXIT FUNCTION
  NEXT i
END FUNCTION

FUNCTION GetKey$
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  GetKey$ = k$
END FUNCTION

FUNCTION Hint$ (t$, v$)
  Hint$ = ""
  IF NOT IsDigits(v$) OR LEN(v$) > 5 THEN EXIT FUNCTION
  n& = VAL(v$)
  IF t$ = "mhz" THEN
    IF n& = 255 THEN Hint$ = "(default)" ELSE Hint$ = "(" + LTRIM$(STR$(n& + 100)) + "MHz)"
  ELSEIF t$ = "clk" THEN
    IF n& = 0 THEN Hint$ = "(default)" ELSE Hint$ = "(" + LTRIM$(STR$(n& / 100)) + "MHz)"
  END IF
END FUNCTION

FUNCTION IsDigits (s$)
  IsDigits = 0
  IF LEN(s$) = 0 THEN EXIT FUNCTION
  FOR k = 1 TO LEN(s$)
    c$ = MID$(s$, k, 1)
    IF c$ < "0" OR c$ > "9" THEN EXIT FUNCTION
  NEXT k
  IsDigits = -1
END FUNCTION

SUB LoadDB
  RESTORE LayoutData
  FOR L = 1 TO 3
    READ LNum(L)
    FOR i = 0 TO LNum(L) - 1
      READ SCls$(L, i), STyp$(L, i), SLab$(L, i), SDsc$(L, i)
    NEXT i
  NEXT L
  RESTORE CardData
  READ NCards
  FOR k = 1 TO NCards
    READ CId$(k), CGrp$(k), CMod$(k), CNote$(k), CFam$(k), CLay(k), CTrl$(k), CNH(k)
    FOR h = 1 TO CNH(k): READ CHdr$(k, h): NEXT h
    FOR i = 0 TO LNum(CLay(k)) - 1: READ CVal$(k, i): NEXT i
  NEXT k
END SUB

FUNCTION NormDate$ (v$)
  ' Matrox writes dates without leading zeros (3/9/1998)
  NormDate$ = v$
  p1 = INSTR(v$, "/"): IF p1 = 0 THEN EXIT FUNCTION
  p2 = INSTR(p1 + 1, v$, "/"): IF p2 = 0 THEN EXIT FUNCTION
  d$ = LEFT$(v$, p1 - 1): m$ = MID$(v$, p1 + 1, p2 - p1 - 1)
  IF NOT IsDigits(d$) OR NOT IsDigits(m$) OR LEN(d$) > 2 OR LEN(m$) > 2 THEN EXIT FUNCTION
  NormDate$ = LTRIM$(STR$(VAL(d$))) + "/" + LTRIM$(STR$(VAL(m$))) + "/" + MID$(v$, p2 + 1)
END FUNCTION

SUB PickCard
  ' full-screen list of all cards; sets Cur (0 = cancelled)
  ps = Cur: IF ps < 1 THEN ps = 1
  pt = ps - 8: IF pt < 1 THEN pt = 1
  DO
    COLOR 0, 7: Fill 1, " Matrox PIN Generator  -  Step 1: choose your card type"
    COLOR 14, 1: Fill 2, " Card version is on the sticker, right after 'ASSEMBLED IN <country>'."
    COLOR 7, 1: Fill 3, ""
    FOR r = 0 TO 17
      k = pt + r
      IF k > NCards THEN
        COLOR 7, 1: Fill 4 + r, ""
      ELSE
        IF k = ps THEN COLOR 0, 3 ELSE COLOR 7, 1
        Fill 4 + r, "  " + CardTitle$(k)
      END IF
    NEXT r
    COLOR 7, 1: Fill 22, ""
    COLOR 0, 7: Fill 23, " Up/Down/PgUp/PgDn = Move    Enter = Select    Esc = Cancel"
    Fill 24, ""
    k$ = GetKey$
    IF LEN(k$) = 2 THEN
      SELECT CASE RIGHT$(k$, 1)
        CASE "H": IF ps > 1 THEN ps = ps - 1
        CASE "P": IF ps < NCards THEN ps = ps + 1
        CASE "I": ps = ps - 18: IF ps < 1 THEN ps = 1
        CASE "Q": ps = ps + 18: IF ps > NCards THEN ps = NCards
        CASE "G": ps = 1
        CASE "O": ps = NCards
      END SELECT
    ELSEIF k$ = CHR$(13) THEN
      Cur = ps: EXIT SUB
    ELSEIF k$ = CHR$(27) THEN
      IF Cur = 0 THEN
        IF AskYN("Quit without creating a PIN file? (Y/N)") THEN Cur = 0: EXIT SUB
      ELSE
        Cur = 0: EXIT SUB
      END IF
    END IF
    IF ps < pt THEN pt = ps
    IF ps > pt + 17 THEN pt = ps - 17
  LOOP
END SUB

FUNCTION PickOption$ (i, r)
  ' pop-up list of the values real cards of this family use
  BuildOptions i
  L = CLay(Cur)
  p = 1
  FOR k = 1 TO NOpt
    IF Opt$(k) = V$(i) THEN p = k
  NEXT k
  n = NOpt: IF n > 12 THEN n = 12
  top0 = r + 1: IF top0 + n + 1 > 22 THEN top0 = r - n - 2
  IF top0 < 2 THEN top0 = 2
  pt = 1
  DO
    IF p < pt THEN pt = p
    IF p > pt + n - 1 THEN pt = p - n + 1
    COLOR 15, 5
    LOCATE top0, 30: PRINT "+" + STRING$(40, "-") + "+";
    FOR k = 0 TO n - 1
      o = pt + k
      t$ = Opt$(o) + " " + Hint$(STyp$(L, i), Opt$(o))
      IF Opt$(o) = CVal$(Cur, i) THEN t$ = t$ + " [factory]"
      IF o = p THEN COLOR 0, 7 ELSE COLOR 15, 5
      LOCATE top0 + 1 + k, 30: PRINT "|" + LEFT$(" " + t$ + SPACE$(40), 40) + "|";
    NEXT k
    COLOR 15, 5
    LOCATE top0 + n + 1, 30: PRINT "+" + LEFT$("- Enter=OK Esc=Cancel " + STRING$(40, "-"), 40) + "+";
    k$ = GetKey$
    IF LEN(k$) = 2 THEN
      IF RIGHT$(k$, 1) = "H" AND p > 1 THEN p = p - 1
      IF RIGHT$(k$, 1) = "P" AND p < NOpt THEN p = p + 1
    ELSEIF k$ = CHR$(13) THEN
      EditOK = -1: PickOption$ = Opt$(p): EXIT FUNCTION
    ELSEIF k$ = CHR$(27) THEN
      EditOK = 0: PickOption$ = V$(i): EXIT FUNCTION
    END IF
  LOOP
END FUNCTION

FUNCTION CurSerial$
  ' serial number currently entered (kept when switching card type)
  CurSerial$ = ""
  L = CLay(Cur)
  FOR i = 0 TO NF - 1
    IF STyp$(L, i) = "serial" THEN CurSerial$ = V$(i)
  NEXT i
END FUNCTION

SUB ResetCard (ser$)
  L = CLay(Cur)
  s$ = ser$
  NF = LNum(L)
  FOR i = 0 TO 35: V$(i) = "": NEXT i
  FOR i = 0 TO NF - 1
    V$(i) = CVal$(Cur, i)
    IF STyp$(L, i) = "serial" THEN
      V$(i) = s$
      ' Compaq OEM entries carry a suggested Matrox-format serial
      IF s$ = "" AND LEFT$(CId$(Cur), 3) = "CPQ" THEN V$(i) = CVal$(Cur, i)
    END IF
  NEXT i
  Sel = 0: Top = 0
  FOR i = 0 TO NF - 1
    IF STyp$(L, i) = "serial" THEN Sel = i
  NEXT i
  IF Sel > VIS - 1 THEN Top = Sel - VIS + 1
END SUB

SUB SaveFile
  e$ = FirstError$
  IF e$ <> "" THEN Msg$ = "Cannot save - " + e$: EXIT SUB
  COLOR 15, 4: Fill 22, " Save as:"
  f$ = UCASE$(LTRIM$(RTRIM$(EditLine$(22, 11, 66, SaveName$, 64))))
  IF NOT EditOK OR f$ = "" THEN EXIT SUB

  FileErr = 0: h = FREEFILE
  OPEN f$ FOR INPUT AS #h
  IF FileErr = 0 THEN
    CLOSE #h
    IF NOT AskYN(f$ + " already exists. Overwrite? (Y/N)") THEN EXIT SUB
  END IF

  L = CLay(Cur)
  FileErr = 0: h = FREEFILE
  OPEN f$ FOR OUTPUT AS #h
  IF FileErr THEN Msg$ = "Cannot write " + f$ + " (error" + STR$(FileErr) + ")": EXIT SUB
  FOR k = 1 TO CNH(Cur): PRINT #h, CHdr$(Cur, k): NEXT k
  FOR i = 0 TO NF - 1
    PRINT #h, LTRIM$(STR$(i)) + ": " + V$(i) + SPACE$(VAL(MID$(CTrl$(Cur), i + 1, 1)))
  NEXT i
  CLOSE #h
  IF FileErr THEN Msg$ = "Error while writing " + f$ + " (error" + STR$(FileErr) + ")": EXIT SUB
  SaveName$ = f$
  Msg$ = "Saved " + f$ + ".  Next: PROGBIOS -i <biosfile>.bin -s " + f$ + " -k"
END SUB

FUNCTION Today$ (t$)
  d$ = DATE$
  y$ = RIGHT$(d$, 4)
  IF t$ = "date2" THEN y$ = RIGHT$(d$, 2)
  Today$ = LTRIM$(STR$(VAL(MID$(d$, 4, 2)))) + "/" + LTRIM$(STR$(VAL(LEFT$(d$, 2)))) + "/" + y$
END FUNCTION

FUNCTION Validate$ (i, v$)
  Validate$ = ""
  L = CLay(Cur): t$ = STyp$(L, i)
  SELECT CASE t$
    CASE "byte", "mhz", "word", "clk"
      IF NOT IsDigits(v$) OR LEN(v$) > 5 THEN Validate$ = "Must be a whole number": EXIT FUNCTION
      n& = VAL(v$)
      mx& = 255
      IF t$ = "word" OR t$ = "clk" THEN mx& = 65535
      IF n& > mx& THEN Validate$ = "Must be 0-" + LTRIM$(STR$(mx&))
    CASE "hex2", "hex8"
      w = 2: IF t$ = "hex8" THEN w = 8
      IF LEN(v$) <> w THEN Validate$ = "Must be" + STR$(w) + " hex digits": EXIT FUNCTION
      FOR k = 1 TO w
        IF INSTR("0123456789ABCDEFabcdef", MID$(v$, k, 1)) = 0 THEN Validate$ = "Must be" + STR$(w) + " hex digits"
      NEXT k
    CASE "bits"
      IF NOT BitsOK(v$) THEN Validate$ = "Groups of 4 bits, e.g. 1111 0000": EXIT FUNCTION
      IF LEN(v$) <> LEN(CVal$(Cur, i)) THEN Validate$ = "Must keep the same number of bits"
    CASE "date2": Validate$ = CheckDate$(v$, 0)
    CASE "date4": Validate$ = CheckDate$(v$, -1)
    CASE "pcb"
      p = INSTR(v$, " ")
      IF p < 2 THEN Validate$ = "Format: number space revision, e.g. 798 2": EXIT FUNCTION
      IF NOT IsDigits(LEFT$(v$, p - 1)) OR NOT IsDigits(MID$(v$, p + 1)) THEN Validate$ = "Format: number space revision, e.g. 798 2"
    CASE "serial"
      IF v$ = "" THEN EXIT FUNCTION
      IF Expert THEN
        IF LEN(v$) > 16 OR INSTR(v$, " ") > 0 THEN Validate$ = "1-16 characters, no spaces"
        EXIT FUNCTION
      END IF
      IF L = 1 THEN
        IF LEN(v$) > 10 THEN Validate$ = "Up to 10 letters/digits": EXIT FUNCTION
        FOR k = 1 TO LEN(v$)
          IF INSTR("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", MID$(v$, k, 1)) = 0 THEN Validate$ = "Up to 10 letters/digits"
        NEXT k
        EXIT FUNCTION
      END IF
      ok = (LEN(v$) = 8)
      IF ok THEN
        FOR k = 1 TO 3
          c$ = MID$(v$, k, 1)
          IF c$ < "A" OR c$ > "Z" THEN ok = 0
        NEXT k
        IF NOT IsDigits(MID$(v$, 4)) THEN ok = 0
      END IF
      IF NOT ok THEN Validate$ = "3 capital letters + 5 digits, e.g. ABS12345"
    CASE "text"
      IF LEN(v$) = 0 THEN Validate$ = "Cannot be empty": EXIT FUNCTION
      IF LEN(v$) > 16 THEN Validate$ = "Max 16 characters"
  END SELECT
END FUNCTION
