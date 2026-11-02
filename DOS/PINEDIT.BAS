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

' ---- Field layouts: count, then class, type, label, description ----
LayoutData:
DATA 26
DATA "fixed","byte","Structure length","Size of the PIN block in bytes."
DATA "card","word","Product ID","Board product identifier."
DATA "user","serial","Serial number","From the sticker on your card."
DATA "card","date4","Manufacturing date","Date the board was made."
DATA "card","word","Revision ID","Board revision."
DATA "card","text","PCB info","PCB information."
DATA "hw","word","RAMDAC type","RAMDAC type code."
DATA "card","text","Pixel clock limits","Pixel clock limits (0 = default)."
DATA "hw","word","LCLK max","0 = default."
DATA "hw","word","Clock setting 9","0 = default."
DATA "hw","clk","Base clock","In 1/100 MHz (5000 = 50.00 MHz)."
DATA "hw","clk","Clock, 4MB","In 1/100 MHz, 0 = default."
DATA "hw","clk","Clock, 8MB","In 1/100 MHz, 0 = default."
DATA "hw","word","Clock modifier","0 = default."
DATA "hw","clk","Test clock","In 1/100 MHz, 0 = default."
DATA "hw","clk","VGA frequency 1","In 1/100 MHz (2517 = 25.17 MHz)."
DATA "hw","clk","VGA frequency 2","In 1/100 MHz (2832 = 28.32 MHz)."
DATA "user","date4","Programming date","Date the PIN was written."
DATA "user","word","Programming count","How many times the PIN has been programmed."
DATA "hw","bits","Options","32 option bits."
DATA "hw","bits","Feature flags","32 feature bits."
DATA "hw","word","VGA clock","VGA clock setting."
DATA "fixed","text","Structure revision","PIN structure revision."
DATA "card","word","Reserved","Unused."
DATA "card","word","Reserved","Unused."
DATA "card","word","Reserved / check","Kept from the factory dump."
DATA 35
DATA "fixed","text","PIN signature","Marks the start of the PIN block."
DATA "fixed","byte","Structure length","Size of the PIN block in bytes."
DATA "fixed","byte","Reserved","Unused."
DATA "fixed","text","PIN version","PIN structure version for this card."
DATA "user","date2","Programming date","Date the PIN was written."
DATA "user","word","Programming count","How many times the PIN has been programmed."
DATA "card","bits","Product ID","Board product identifier bits."
DATA "user","serial","Serial number","From the sticker on your card: 3 capital letters + 5 digits."
DATA "card","text","Card version","Card version from the sticker, e.g. 001B, 205A."
DATA "card","pcb","PCB number + revision","Printed on the PCB, e.g. 644 00 (major / minor revision)."
DATA "hw","bits","Feature flags","32 feature bits."
DATA "hw","hex2","RAMDAC type","RAMDAC type code."
DATA "hw","mhz","RAMDAC speed","Max RAMDAC speed."
DATA "hw","mhz","Max pixel clock","Max pixel clock."
DATA "hw","mhz","Graphics engine clock","System / engine PLL."
DATA "hw","mhz","Memory clock","Memory clock."
DATA "hw","mhz","Engine clock, 4MB","Engine clock used with 4MB memory."
DATA "hw","mhz","Engine clock, 8MB","Engine clock used with 8MB memory."
DATA "hw","byte","Clock modifier","Clock modifier."
DATA "hw","byte","Test clock","Test clock (255 = default)."
DATA "hw","byte","VGA frequency 1","Default VGA pixel frequency 1 (255 = default)."
DATA "hw","byte","VGA frequency 2","Default VGA pixel frequency 2 (255 = default)."
DATA "hw","bits","MCTLWTST memory timing","Memory controller wait-state bits."
DATA "hw","bits","Video control","Video control bits."
DATA "hw","mhz","Engine clock, 12MB","Engine clock used with 12MB memory."
DATA "hw","mhz","Engine clock, 16MB","Engine clock used with 16MB memory."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "hw","byte","Reserved","Unused (255)."
DATA "fixed","byte","PIN checksum","Kept from the factory dump; PROGBIOS accepts edited PINS files without changing it."
DATA 35
DATA "fixed","text","PIN signature","Marks the start of the PIN block."
DATA "fixed","byte","Structure length","Size of the PIN block in bytes."
DATA "fixed","byte","Reserved","Unused."
DATA "fixed","text","PIN version","PIN structure version for this card."
DATA "user","date4","Programming date","Date the PIN was written."
DATA "user","word","Programming count","How many times the PIN has been programmed."
DATA "card","bits","Product ID","Board product identifier bits."
DATA "user","serial","Serial number","From the sticker on your card: 3 capital letters + 5 digits."
DATA "card","text","Card version","Card version from the sticker, e.g. 001B, 205A."
DATA "card","pcb","PCB number + revision","Printed on the PCB, e.g. 644 00 (major / minor revision)."
DATA "hw","mhz","Max RAMDAC frequency","130 = 230 MHz, 150 = 250 MHz."
DATA "hw","mhz","Max pixel clock, 8 bpp","Stored as MHz-100."
DATA "hw","mhz","Max pixel clock, 16 bpp","Stored as MHz-100."
DATA "hw","mhz","Max pixel clock, 24 bpp","Stored as MHz-100."
DATA "hw","mhz","Max pixel clock, 32 bpp","Stored as MHz-100."
DATA "hw","byte","VGA1 pixel clock","255 = default."
DATA "hw","byte","VGA2 pixel clock","255 = default."
DATA "hw","byte","VGA graphics clock","Graphics clock in VGA modes, MHz."
DATA "hw","byte","2D clock, no mem. expansion","Graphics clock without memory expansion, MHz."
DATA "hw","byte","2D clock, +2MB expansion","Graphics clock with 2MB memory expansion, MHz."
DATA "hw","byte","2D clock, +4MB expansion","Graphics clock with 4MB memory expansion, MHz."
DATA "hw","byte","2D clock, +8MB expansion","Graphics clock with 8MB memory expansion, MHz."
DATA "hw","hex8","Memory control word","Memory controller timing (MCTLWTST), hex."
DATA "hw","byte","Board options","Undocumented option byte."
DATA "hw","byte","Video output options","Video output options."
DATA "hw","byte","Option byte 25","Undocumented (memory configuration)."
DATA "hw","byte","Option byte 26","Undocumented."
DATA "hw","byte","Option byte 27","Undocumented (memory read-back timing)."
DATA "hw","byte","Option byte 28","Undocumented (memory read-back timing)."
DATA "hw","byte","Option byte 29","Undocumented (OPTION2 register)."
DATA "hw","byte","Option byte 30","Undocumented."
DATA "hw","byte","3D graphics clock","Graphics clock for 3D, MHz."
DATA "hw","byte","Option byte 32","Undocumented."
DATA "hw","byte","Option byte 33","Undocumented."
DATA "fixed","byte","PIN checksum","Covers 8 hidden PINS bytes PROGBIOS does not dump, so it cannot be recalculated from this file; kept from the factory dump."

' ---- Cards: id, group, model, note, family, layout, trailing spaces, header count, header lines, values ----
CardData:
DATA 38
' MILL
DATA "MILL","Millennium","Millennium (TVP3026, old PINS)","Old v1 PINS layout","MILL",1,"00000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox Millennium - TVP 3026","VGA Enabled - BIOS V1.5 ",""
DATA "64","0","0000000","13/12/1995","5","1152 4","0","0 0","0","0","5000","0"
DATA "0","0","0","2517","2832","13/12/1995","3","0000 0000 0000 0000 0000 0000 0000 0000","0000 0000 0000 0000 0000 0000 0000 0000","259","0.0","0"
DATA "0","46336"
' MYST004
DATA "MYST004","Mystique","Model 004","","MYST",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox Mystique","VGA Enabled - BIOS V1.8 ",""
DATA "PIN","64","255","2.0","18/10/98","3","0000 0001 0000 0000","ABC82266","004","644 0","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "70","70","60","255","60","50","55","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","129"
' MYST005
DATA "MYST005","Mystique","Model 005 (MYST/4I)","","MYST",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox Mystique","VGA Enabled - BIOS V1.4 ",""
DATA "PIN","64","255","2.0","16/6/98","6","0000 0001 0000 0000","ABD94363","005","644 0","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "70","70","60","255","60","50","55","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","254"
' MYST006
DATA "MYST006","Mystique","Model 006 (MYST/4I)","","MYST",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox Mystique","VGA Enabled - BIOS V1.8 ",""
DATA "PIN","64","255","2.0","3/10/98","5","0000 0000 0000 0000","EAE83178","006","644 0","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "70","70","60","255","60","50","55","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","100"
' CPQ296677
DATA "CPQ296677","Mystique 220","Compaq OEM 296677-001 (board 007414-001)","Compaq OEM - based on Model 311; ID fields estimated","M220",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.80d","(C) Matrox Graphics Inc. (1998)","","Matrox Mystique 220","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","2.1","29/1/98","2","0000 0000 0000 0000","CPQ24089","311","644 3","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "120","120","66","255","66","60","50","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","162"
' M220305
DATA "M220305","Mystique 220","Model 305","","M220",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox Mystique 220","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","2.1","23/1/98","1","0001 0001 0000 0000","GAC73382","305","644 3","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "120","120","66","255","66","60","50","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","87"
' M220308
DATA "M220308","Mystique 220","Model 308","PINS v2.0","M220",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.80d","(C) Matrox Graphics Inc. (1998)","","Matrox Mystique 220","VGA Enabled - BIOS V1.8 ",""
DATA "PIN","64","255","2.0","30/12/98","5","0000 0001 0000 0000","CBY54268","308","644 3","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "120","120","66","255","66","60","255","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","24"
' M220311
DATA "M220311","Mystique 220","Model 311","","M220",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.80d","(C) Matrox Graphics Inc. (1998)","","Matrox Mystique 220","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","2.1","29/1/98","2","0000 0000 0000 0000","EBB51410","311","644 3","1111 1111 1111 1111 1111 1111 1111 1111","00"
DATA "120","120","66","255","66","60","50","255","255","255","1111 1111","1110 1110"
DATA "255","255","255","255","255","255","255","255","255","255","162"
' MIL27030
DATA "MIL27030","Millennium II","Model 004 (703-00 rev.A) PCI","","MIL2",2,"10000000000000000000000011111111110",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox Millennium II","VGA Enabled - BIOS V1.1 ",""
DATA "PIN","64","255","2.1","14/3/98","2","0001 0000 0000 0000","CCJ11039","004","703 0","1111 1111 1111 1111 1111 1111 1111 1111","26"
DATA "150","150","54","255","66","62","54","255","255","255","1111 1111","1110 1110"
DATA "58","54","255","255","255","255","255","255","255","255","138"
' G100100A
DATA "G100100A","G100","Model 100A (4MB)","","G100",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G100 AGP","VGA Enabled - BIOS V1.1 ",""
DATA "PIN","64","255","3.0","12/5/1998","3","0001 0001 0000 0000","ABR54247","100A","790 1","130","130"
DATA "130","116","62","255","255","62","62","62","62","62","01032521","0"
DATA "238","116","64","255","255","255","255","255","255","255","53"
' G1PR101
DATA "G1PR101","G100","Productiva 8MB, Model 101 (G+/PROA/8BN/5)","","G100",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G100 AGP","VGA Enabled - BIOS V1.4 ",""
DATA "PIN","64","255","3.0","11/8/1998","5","0001 0000 0010 0000","CCL31247","101","815 1","130","130"
DATA "130","76","35","255","255","66","66","66","66","66","01232521","21"
DATA "238","116","128","255","255","255","255","255","255","255","37"
' G2SD001A
DATA "G2SD001A","G200 SD (G2+/SDA)","Model 001A","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","31/8/1998","4","0000 0000 0000 0000","CBD35231","001A","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","255","70"
' G2SD001B
DATA "G2SD001B","G200 SD (G2+/SDA)","Model 001B","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.2 ",""
DATA "PIN","64","255","3.0","15/8/1998","3","0000 0001 0000 0000","FAG00217","001B","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","79","67","255","79"
' G2SD001C
DATA "G2SD001C","G200 SD (G2+/SDA)","Model 001C","","G200",3,"00000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.2",""
DATA "PIN","64","255","3.0","3/8/1998","2","0000 0000 0000 0000","ABT03808","001C","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","255","79"
' G2SD003A
DATA "G2SD003A","G200 SD (G2+/SDA)","Model 003A","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","3.0","16/10/1998","4","0000 0010 0000 0000","ABS77832","003A","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","255","247"
' G2SD004
DATA "G2SD004","G200 SD (G2+/SDA)","Model 004","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","3.0","1/11/1998","3","0000 0001 0000 0000","ABT57874","004","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","255","35"
' G2SD004C
DATA "G2SD004C","G200 SD (G2+/SDA)","Model 004C","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","1/9/1998","2","0000 0001 0000 0000","FAG91249","004C","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","255","48"
' G2SD005A
DATA "G2SD005A","G200 SD (G2+/SDA)","Model 005A","","G200",3,"00000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.80d","(C) Matrox Graphics Inc. (1998)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.6",""
DATA "PIN","64","255","3.0","29/11/1998","4","0001 0001 0000 0000","FAH75137","005A","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","255","196"
' G2MS000
DATA "G2MS000","Millennium G200 SD (G2+/MSDA/8)","Model 000","250 MHz RAMDAC","G200",3,"10000001100000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","5/11/1998","2","0000 0001 0000 0000","FAJ19396","000","834 0","150","150"
DATA "150","114","62","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","255","84","67","221","217"
' G2MY000A
DATA "G2MY000A","Mystique G200 (G2+/MYSA)","Model 000A","","G200",3,"00000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 TVO",""
DATA "PIN","64","255","3.0","7/10/1998","4","0001 0001 0100 0000","FAH05735","000A","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","254","84","67","255","196"
' G2MY000B
DATA "G2MY000B","Mystique G200 (G2+/MYSA)","Model 000B","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","14/11/1998","4","0000 0000 0100 0000","ABT93273","000B","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","254","84","67","255","203"
' G2MY001C
DATA "G2MY001C","Mystique G200 (G2+/MYSA)","Model 001C","250 MHz RAMDAC","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.78d","(C) Matrox Graphics Inc. (1998)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.6 ",""
DATA "PIN","64","255","3.0","1/12/1998","11","0000 0000 0100 0000","ABU39209","001C","834 0","150","150"
DATA "150","114","62","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","254","84","67","221","85"
' G2MY002
DATA "G2MY002","Mystique G200 (G2+/MYSA)","Model 002","","G200",3,"00000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3",""
DATA "PIN","64","255","3.0","29/9/1998","5","0001 0001 0100 0000","FAH93346","002","834 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","254","79","67","255","1"
' G2MY002A
DATA "G2MY002A","Mystique G200 (G2+/MYSA)","Model 002A","250 MHz RAMDAC","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","28/9/1998","2","0000 0001 0100 0000","FAH86014","002A","834 0","150","150"
DATA "150","114","62","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","254","84","67","221","176"
' G2MI201
DATA "G2MI201","Millennium G200 (G2+/MILA)","Model 201","","G200",3,"10000001100000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","3/9/1998","4","0001 0000 0110 0000","ABS12345","201","798 2","150","150"
DATA "150","103","52","255","255","62","62","62","62","62","04244ca1","0"
DATA "238","3","128","136","0","8","255","84","67","255","25"
' G2MI202
DATA "G2MI202","Millennium G200 (G2+/MILA)","Model 202","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","3.0","17/10/1998","4","0000 0001 0110 0000","FAF58641","202","798 2","150","150"
DATA "150","114","62","255","255","66","66","66","66","66","04244ca1","0"
DATA "238","3","128","136","0","8","255","84","67","255","208"
' G2MI203A
DATA "G2MI203A","Millennium G200 (G2+/MILA)","Model 203A","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","3/9/1998","3","0001 0010 0110 0000","ABS58189","203A","798 2","150","150"
DATA "150","103","52","255","255","62","62","62","62","62","042450a1","0"
DATA "238","3","128","136","0","8","255","84","67","255","193"
' G2MI205A
DATA "G2MI205A","Millennium G200 (G2+/MILA)","Model 205A","","G200",3,"10000001100000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","5/9/1998","3","0001 0010 0110 0000","ABS12345","205A","798 2","150","150"
DATA "150","103","52","255","255","62","62","62","62","62","042450a1","0"
DATA "238","3","128","136","0","8","255","84","67","255","181"
' G2MI206
DATA "G2MI206","Millennium G200 (G2+/MILA)","Model 206","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","3.0","15/10/1998","1","0000 0000 0110 0000","ABS12345","206","798 2","150","150"
DATA "150","124","68","255","255","69","69","69","69","69","04244ca1","0"
DATA "238","3","128","136","0","8","255","84","67","255","148"
' G2MI206X
DATA "G2MI206X","Millennium G200 (G2+/MILA)","Model 206 (faster memory)","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","4/9/1998","2","0001 0000 0110 0000","CCR27809","206","798 2","150","150"
DATA "150","103","52","255","255","62","62","62","62","62","042450a1","0"
DATA "238","3","128","136","0","8","255","84","67","255","4"
' G2MI206A
DATA "G2MI206A","Millennium G200 (G2+/MILA)","Model 206A","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","3/9/1998","2","0001 0001 0110 0000","FAH10855","206A","798 2","150","150"
DATA "150","103","52","255","255","62","62","62","62","62","042450a1","0"
DATA "238","3","128","136","0","8","255","84","67","255","211"
' G2MI207A
DATA "G2MI207A","Millennium G200 (G2+/MILA)","Model 207A","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","7/10/1998","2","0001 0010 0110 0000","ABU12345","207A","798 2","150","150"
DATA "150","132","76","255","255","66","72","66","66","66","042450a1","0"
DATA "238","3","128","136","0","8","255","90","67","204","124"
' G2MI208
DATA "G2MI208","Millennium G200 (G2+/MILA)","Model 208","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.78d","(C) Matrox Graphics Inc. (1998)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.6 ",""
DATA "PIN","64","255","3.0","10/12/1998","3","0000 0000 0110 0000","CCU48389","208","798 2","150","150"
DATA "150","114","62","255","255","66","66","66","66","66","042450a1","0"
DATA "238","3","128","136","0","8","255","84","67","255","187"
' G2MI209
DATA "G2MI209","Millennium G200 (G2+/MILA)","Model 209","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.78d","(C) Matrox Graphics Inc. (1998)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.6 ",""
DATA "PIN","64","255","3.0","9/12/1998","3","0001 0000 0110 0000","CCV45875","209","798 2","150","150"
DATA "150","132","76","255","255","66","72","66","66","66","042450a1","0"
DATA "238","3","128","136","0","8","255","90","67","204","201"
' G2MI209A
DATA "G2MI209A","Millennium G200 (G2+/MILA)","Model 209A","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.73d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","21/10/1998","2","0001 0010 0110 0000","ABV07128","209A","798 2","150","150"
DATA "150","132","76","255","255","66","72","66","66","66","042450a1","0"
DATA "238","3","128","136","0","8","255","90","67","204","114"
' G2MI209B
DATA "G2MI209B","Millennium G200 (G2+/MILA)","Model 209B","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.80d","(C) Matrox Graphics Inc. (1998)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.3 ",""
DATA "PIN","64","255","3.0","6/11/1998","2","0001 0001 0110 0000","GAK46469","209B","798 2","150","150"
DATA "150","103","52","255","255","62","62","62","62","62","042450a1","0"
DATA "238","3","128","136","0","8","255","84","67","255","89"
' G2MA002A
DATA "G2MA002A","Marvel G200","Model 002A (no TV)","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.78d","(C) Matrox Graphics Inc. (1998)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.5 ",""
DATA "PIN","64","255","3.0","20/10/1998","3","0000 0001 1000 0000","ABU00675","002A","818 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","242","84","67","255","43"
' G2MT003A
DATA "G2MT003A","Marvel G200","Model 003A (G200TV)","","G200",3,"10000000000000000000000000000000000",6
DATA "MGA Bios Programming Utility v1.76d","(C) Matrox Graphics Inc. (1997)","","Matrox MGA-G200 AGP","VGA Enabled - BIOS V1.4 TVO ",""
DATA "PIN","64","255","3.0","28/10/1998","4","0000 0000 1000 0000","ABU31574","003A","818 0","130","130"
DATA "130","103","52","255","255","62","62","62","62","62","04244ca1","16"
DATA "238","4","128","136","0","8","226","84","67","255","52"

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
