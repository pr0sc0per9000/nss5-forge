' TScreen_Difficulty.CreateScreen
' VA 0x0052571f   1498 bytes   class-table slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (1498/1498, original length from Ghidra's inventory)
' Gadget-construction family (codegen-patterns.md 12.2 / 3d) -- same shape as
' TScreen_TestMenu.CreateScreen / TScreen_Dilemma.CreateScreen / TScreen_ContinentalComps.
' Builds the difficulty-select screen: title bar, a bottom nav panel (empty, present only for
' layout), two full-width instruction labels, then three side-by-side panels (easy/normal/hard)
' each holding one CreateButton (the difficulty pick) and one instruction TLabel, stacked
' vertically with `y :+ h + 10` between rows (same accumulator idiom as codegen-patterns.md
' 16.5/18 and TScreen_TestMenu.CreateScreen).
'
' ASSUMPTIONS -- module Globals (declared TYPE is load-bearing):
'   0x00C64500 g_screen_difficulty:TScreen   construction site = TScreen.CreateScreen
'   0x00C6EFDC g_screenwidth:Int             bare dword read, no refcount (majority naming
'     for this address across the corpus, e.g. TScreen.CreateScreen, TScreen_Dilemma)
'   0x00C6EFE0 g_screenheight:Int            bare dword read, no refcount
'
' Class-table slots (class_tables.tsv / vtable_map.tsv):
'   TScreen+0x38 CreateScreen($,:TImage,()i,()i):TScreen ; TScreen+0x40 AddGadget(:TGadget)i
'   TPanel+0x88  CreatePanel  (13-arg sig) ; TLabel+0x88 CreateLabel (21-arg sig)
'   TButton+0x88 CreateButton (15-arg sig)
' This Type's own class-table slots, read as `push dword ptr [classtable+slot]` when passed as
' a callback VALUE (never called from inside this function): +0x38 ButtonEasy, +0x3c
' ButtonNormal, +0x40 ButtonHard.
'
' Every GetText(...) call in the decompilation takes exactly ONE argument (1831 corroborating
' sites, codegen-patterns.md 3a) -- the extra operands Ghidra shows inside the GetText(...)
' parens actually belong to the ENCLOSING CreatePanel/CreateLabel/CreateButton call. Both
' fDraw/fUpdate arguments to TScreen.CreateScreen are the compiler's empty-function default
' (FUN_005B95D0), i.e. source-level Null (codegen-patterns.md 10.6). String literals ("pan_nav",
' "pan_title", "Difficulty", "difficulty_Easy"/"Normal"/"Hard", the four CMESSAGE_DIFFICULTY*
' keys, every widget name) read directly out of NSS5.exe with harness.read_string().
'
' FIRST DRAFT (all-literal x/y/w/h) was 245 bytes SHORT (1253/1498): localise_diff showed every
' gap was a `push <reg>`/arithmetic-then-push sequence collapsed to a `push imm32`. The four
' widget-geometry values are real Locals x,y,w,h (=10,10,780,40 initially, declared in that
' order right after the pan_nav AddGadget -- store order in the disassembly IS declaration
' order), reused and reassigned across the easy/normal/hard rows: y=70,h=147 before the "easy"
' row, then `y :+ h + 10` before "normal" and again before "hard" (h stays 147). Per-widget
' geometry is arithmetic on those Locals, not fresh numbers: button x=x+10, y=y+10,
' w=w/2-15, h=h-20; the second label's x is x+w/2+5 (the div-by-2 is bcc's signed
' cdq/and/add/sar idiom for `/2`, confirmed by codegen-patterns.md 11.1-style reasoning). The
' second instruction label's y (550) and lbl_instrucs1/pan_title/pan_nav's geometry are genuine
' literals/Globals (no register load precedes their push), so those stay as written.
'
' ORACLE: mode=reloc  matched=1498/1498  STATUS=MATCH.
'!Global g_screen_difficulty:TScreen
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
	Function CreateScreen()
		g_screen_difficulty = TScreen.CreateScreen("difficulty", Null, Null, Null)
		g_screen_difficulty.AddGadget(TPanel.CreatePanel("pan_title", GetText("Difficulty"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
		g_screen_difficulty.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		Local x:Int = 10
		Local y:Int = 10
		Local w:Int = 780
		Local h:Int = 40
		g_screen_difficulty.AddGadget(TLabel.CreateLabel("lbl_instrucs1", GetText("CMESSAGE_DIFFICULTYSET1"), x, y, w, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_screen_difficulty.AddGadget(TLabel.CreateLabel("lbl_instrucs2", GetText("CMESSAGE_DIFFICULTYSET2"), x, 550, w, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y = 70
		h = 147
		g_screen_difficulty.AddGadget(TPanel.CreatePanel("pan_easy", "", x, y, w, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0))
		g_screen_difficulty.AddGadget(TButton.CreateButton("btn_easy", GetText("difficulty_Easy"), x + 10, y + 10, w / 2 - 15, h - 20, 1, 4, "FFFFFF", "FFFFFF", Null, ButtonEasy, 1.0, 1, ""))
		g_screen_difficulty.AddGadget(TLabel.CreateLabel("lbl_instrucseasy", GetText("CMESSAGE_DIFFICULTYEASY"), x + w / 2 + 5, y + 10, w / 2 - 15, h - 20, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_screen_difficulty.AddGadget(TPanel.CreatePanel("pan_normal", "", x, y, w, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0))
		g_screen_difficulty.AddGadget(TButton.CreateButton("btn_normal", GetText("difficulty_Normal"), x + 10, y + 10, w / 2 - 15, h - 20, 1, 4, "FFFFFF", "FFFFFF", Null, ButtonNormal, 1.0, 1, ""))
		g_screen_difficulty.AddGadget(TLabel.CreateLabel("lbl_instrucsnormal", GetText("CMESSAGE_DIFFICULTYNORMAL"), x + w / 2 + 5, y + 10, w / 2 - 15, h - 20, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_screen_difficulty.AddGadget(TPanel.CreatePanel("pan_hard", "", x, y, w, h, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0))
		g_screen_difficulty.AddGadget(TButton.CreateButton("btn_hard", GetText("difficulty_Hard"), x + 10, y + 10, w / 2 - 15, h - 20, 1, 4, "FFFFFF", "FFFFFF", Null, ButtonHard, 1.0, 1, ""))
		g_screen_difficulty.AddGadget(TLabel.CreateLabel("lbl_instrucshard", GetText("CMESSAGE_DIFFICULTYHARD"), x + w / 2 + 5, y + 10, w / 2 - 15, h - 20, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
	End Function
