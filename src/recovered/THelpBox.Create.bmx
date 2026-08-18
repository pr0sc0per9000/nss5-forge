' THelpBox.Create
' VA 0x0051b436   1360 bytes   class-table slot 0x30   sig (:TGadget,i,i,i,i,$,i,i):THelpBox
' KIND=Function (static, no implicit Self)
'
' Builds a tooltip/help-bubble box anchored to a TGadget: positions itself relative to the
' anchor per a 4-way `pos` mode (below/above/right/left), clamps into the screen, then
' constructs two instruction TLabels (lbl_Help1/lbl_Help2, stacked) and two TButtons
' (btn_Ok, btn_EndTutorial). Called from TScreen.CreateScreen.bmx (already banked) with
' g=Null, pos=0 -- the whole anchor-positioning Select is then skipped and the caller's raw
' x/y are used as-is.
'
' PARAMETERS (ours; signature order only) a0:TGadget g, a1:Int x, a2:Int y, a3:Int w,
' a4:Int h, a5:String text, a6:Int pos, a7:Int iconpos.
'
' FIELD OFFSETS
'   THelpBox (object_model.json): +8 lbl_Help1:TLabel +0xC lbl_Help2:TLabel
'     +0x10 btn_Ok:TButton +0x14 btn_EndTutorial:TButton
'   TGadget (inherited by TLabel/TButton, and read directly off the anchor `g`):
'     +0x20 x:Float +0x24 y:Float +0x28 h:Float +0x2C w:Float
'
' SOURCE FORM -- read from the RAW disassembly, not the Ghidra-decompiled C, because the
' decompiler constant-folds register reads inside the `pos=2` branch into literal "2" and
' "0x28" that are NOT what the machine code does (see below). Trusting the decompiled C's
' folded literals here would have cost 1 byte per occurrence (`push imm8` 6A 02 vs
' `push [ebp+0x20]` FF 75 20).
'   * `If w = 0 Or h = 0 Then w=0xD7:h=0x96` -- BlitzMax's Or short-circuits (the h=0 test is
'     skipped entirely when w=0 is already true), matching the `sete`/`jne`-over-second-test
'     shape exactly.
'   * The four `pos` cases are a `Select` (codegen-patterns.md 10.2: every compare bunched at
'     the top, jumping to bodies that all sit past the last compare, with no Default -- the
'     fall-through is the join point after End Select). Each case reassigns the PARAMETERS x
'     and y in place (edi/ebx keep holding them for the rest of the function).
'   * `w/2`, `h/2` inside the float math are bcc's Int-division shift idiom
'     (cdq/and edx,1/add/sar) fed back into the FPU with `fild`/`fsubp` -- i.e. plain
'     `w / 2` / `h / 2` (Int arithmetic), not float division.
'   * Clamp-to-screen block after the Select matches codegen-patterns.md 3f's guard shape
'     exactly (early corrective reassignment, not a nested If/Else).
'   * `lbl_Help1`'s `align` argument is ALWAYS `iconpos` (a7) in both branches; only the two
'     trailing Int slots (args 17/18, elsewhere `pos`/`ic`) differ between the `pos=2` branch
'     (hard-coded 0/0 there) and the general branch (reads a6/ic for real) -- and it is
'     `lbl_Help2` that gets the real a6/ic reads on the `pos=2` side. This is the one place a
'     raw memory `push [ebp+0x20]` inside the `pos=2` arm proves the source still reads the
'     real parameter, not a folded constant.
'   * The `a6 <> 2` If/Else is the solo-relational branch-swap (codegen-patterns.md 21): `je`
'     lands on the `pos=2` arm placed SECOND in the source, so the written condition has to be
'     the negation (`<> 2`) with Then/Else swapped relative to the natural "if pos=2" reading.
'   * `lbl_Help2`'s y is `Int(y + lbl_Help1.h)`, recomputed with no caching (bcc does no CSE,
'     codegen-patterns.md 6). `btn_Ok`/`btn_EndTutorial`'s y is `Int(lbl_Help2.y + 6.0)`,
'     independently recomputed at each of the two call sites for the same reason.
'   * `New THelpBox` emits only `_bbObjectNew` with no follow-up call to THelpBox.New --
'     THelpBox.New (already banked, 0x0051b391) is compiler-generated-empty, so bcc calls it
'     nowhere, including here.
'
' ORACLE: mode=reloc  matched=1360/1360  STATUS=MATCH.
Function Create(a0:TGadget, a1:Int, a2:Int, a3:Int, a4:Int, a5:String, a6:Int, a7:Int)
	Local box:THelpBox = New THelpBox
	If a3 = 0 Or a4 = 0
		a3 = 215
		a4 = 150
	EndIf
	Local ic:Int = 0
	If a0 <> Null
		Select a6
			Case 1
				a1 = Int(a0.x + a0.w / 2.0 - a3 / 2)
				a2 = Int(a0.y + a0.h + 12.0)
			Case 2
				a1 = Int(a0.x + a0.w / 2.0 - a3 / 2)
				a2 = Int(a0.y - a4 - 12.0)
			Case 3
				a1 = Int(a0.x + a0.w + 12.0)
				a2 = Int(a0.y + a0.h / 2.0 - a4 / 2)
			Case 4
				a1 = Int(a0.x - a0.w - a3 - 12.0)
				a2 = Int(a0.y + a0.h / 2.0 - a4 / 2)
		End Select
	EndIf
	If a1 + a3 > g_screenwidth - 10
		ic = (a1 + a3) - (g_screenwidth - 10)
		a1 = g_screenwidth - a3 - 10
	EndIf
	If a1 < 10
		ic = a1 - 10
		a1 = 10
	EndIf
	If a2 + a4 > g_screenheight - 10
		a2 = g_screenheight - a4 - 10
	EndIf
	If a2 < 10
		a2 = 10
	EndIf
	If a6 <> 2
		box.lbl_Help1 = TLabel.CreateLabel("lbl_Help1", a5, a1, a2, a3, a4 - 40, a7, "666666", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, a6, ic, 0, "", 0)
		box.lbl_Help2 = TLabel.CreateLabel("lbl_Help2", "", a1, Int(a2 + box.lbl_Help1.h), a3, 40, a7, "666666", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
	Else
		box.lbl_Help1 = TLabel.CreateLabel("lbl_Help1", a5, a1, a2, a3, a4 - 40, a7, "666666", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		box.lbl_Help2 = TLabel.CreateLabel("lbl_Help2", "", a1, Int(a2 + box.lbl_Help1.h), a3, 40, a7, "666666", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, a6, ic, 0, "", 0)
	EndIf
	box.btn_Ok = TButton.CreateButton("btn_Ok", "", a1 + a3 - 85, Int(box.lbl_Help2.y + 6.0), 80, 28, 1, 2, "FFFFFF", "FFFFFF", g_icon_ok, TScreen.ButtonHelpOk, 1.0, 1, "")
	box.btn_EndTutorial = TButton.CreateButton("btn_EndTutorial", GetText("End Tutorial"), a1 + 6, Int(box.lbl_Help2.y + 6.0), 120, 28, 1, 2, "FFFFFF", "FFFFFF", g_icon_endtutorial, TScreen.ButtonEndTutorial, 1.0, 1, "")
	Return box
End Function
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_icon_ok:TImage
'!Global g_icon_endtutorial:TImage
