' GLOBAL RENAMED (2026-08-15): g_screen -> g_curscreen. Same slot, 0x00C61700 -- THE ACTIVE
' SCREEN. This one slot carried FOUR names across the corpus: g_curscreen (majority, 8
' declarers), g_currentscreen, g_screen, and the decoder auto-name g_Object101. In the
' assembled program those became four independent Globals, so TScreen.SetActive wrote
' the newly-activated screen into one while the main loop's TScreen.Update and
' TScreen.Render read others. The game booted, opened its window and ran the
' fixed-timestep loop -- and drew the boot 'loading' screen forever, because the screen
' the loop rendered was never the screen SetActive had set. Byte-neutral; confirmed
' with scripts/reverify.py.
' Scope check before renaming: g_Object101 resolves to 0x00C61700 and nothing else
' anywhere in src/recovered. g_screen was renamed ONLY in TScreen.Update.bmx, the one
' file that states the address -- the other 8 g_screen declarers record no VA, and the
' name->address map is many-to-many, so sweeping it would be a guess.
' TScreen.Update
' VA 0x00511237   555 bytes   class-table slot 0x78   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (555/555, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=36)
' Body-only format: statements only, no parameters.
' assumptions (module Globals, names ours):
'   0x00C61700 : TScreen  -- the active screen. globals_final.tsv has bare Object/usage/low;
'                            TScreen is forced by slots 0x50 GetGadgetList and 0x7C CheckInput
'                            and by the fUpdate function-pointer Field at +0x18.
'   0x00C61CF8 : TGadget  -- the focused gadget. It must be a PROPER SUPERTYPE of TInputBox
'                            and TTable, because both accesses go through an explicit
'                            bbObjectDowncast, while `g_focus.Update()` is a direct slot-0x34
'                            call -- TGadget.Update.
' slots resolved: TScreen 0x50=GetGadgetList, 0x7C=CheckInput; TGadget 0x34=Update,
'   0x38=UpdateChildren, 0x3C=UpdateToolTip; TTable 0xBC=UpdateActivated;
'   TCombo/TInputBox/TProgressBar 0x34=Update (each its own override).
'   Downcast class tables: 0x00C63058=TCombo, 0x00C62558=TInputBox, 0x00C62B24=TTable,
'   0x00C62150=TGadget, 0x00C63720=TProgressBar.
' fields: TCombo.activated +0x64, TInputBox.gettinginput +0x60, TTable.activated +0x6C,
'   TScreen.fUpdate +0x18 (a ()i function pointer, compared against the empty function
'   0x005B95D0 per 10.6, i.e. plain `If g_curscreen.fUpdate`).
' load-bearing shape: the SECOND operand of each `And` is the bare truth value, not `<> 0`.
' Written as `<> 0` it gains a `cmp eax,0 / setne al / movzx eax,al` triple -- 9 bytes each,
' 18 bytes over, which was exactly the initial overshoot. bcc does no CSE, so the downcast
' really is emitted twice per branch.
	Function Update:Int()
		'!Global g_curscreen:TScreen
		'!Global g_focus:TGadget
		If g_curscreen <> Null
			For Local cmb:TCombo = EachIn g_curscreen.GetGadgetList()
				If cmb.activated <> 0
					cmb.Update()
					Return 0
				EndIf
			Next
			If TInputBox(g_focus) <> Null And TInputBox(g_focus).gettinginput
				g_focus.Update()
			ElseIf TTable(g_focus) <> Null And TTable(g_focus).activated
				TTable(g_focus).UpdateActivated()
			Else
				g_curscreen.CheckInput()
				For Local g:TGadget = EachIn g_curscreen.GetGadgetList()
					g.Update()
					g.UpdateChildren()
					g.UpdateToolTip()
				Next
			EndIf
			For Local pb:TProgressBar = EachIn g_curscreen.GetGadgetList()
				pb.Update()
			Next
			If g_curscreen.fUpdate Then g_curscreen.fUpdate()
		EndIf
	End Function
