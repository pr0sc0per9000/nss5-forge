' TScreen.TabToGadget  -- KIND=Method, slot 0x8c
' VA 0x00512441   539 bytes   sig ()i
' byte-identical vs NSS5.exe (539/539, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=35)
' Body-only format: statements only, Self implicit.
'
' What it does: advance the keyboard focus to the next focusable, visible gadget on this
' screen, wrapping round to the first one.
'
' ASSUMPTIONS (Global names are ours; the declared TYPES are load-bearing)
'  * 0x00C61CF8 : TGadget (g_activeGadget) -- the engine's active-gadget cell, same
'    Global that TGadget.GetActiveGadgetName and TScreen.FindNewActiveGadget read.
'    globals_final.tsv has it as Object/usage/low.
'  * 0x00C61700 : TScreen  (g_activeScreen) -- globals_final.tsv has it Object/usage/low.
'    Typed TScreen because the call site is `mov eax,[g] / mov eax,[eax] / call [eax+0x60]`
'    with a SINGLE String argument, and TScreen slot 0x60 is SetActiveGadget ($)i.
'  * 0x00C6173C : Int (g_screenFlag) -- Int/usage/medium, 36 dword writes, bare mov here.
'  * FUN_005B478C = _brl_polledinput_FlushKeys (brl_functions_inferred.tsv; per 10.8 the
'    inferred table does get masked, and it did here).
'  * FUN_00505B91 = LogLine, FUN_004A8F60 = bbObjectDowncast.
'  * TGadget.alive +0x38, TGadget.hidden +0x3c, TGadget.name +0x0c,
'    TInputBox.gettinginput +0x60. TScreen.GetGadgetList is slot 0x50.
'
' CODEGEN NOTES -- three separate forms had to be pinned down, in this order:
'  1. `If Not first Then first = g`, NOT `If first = Null`. The original has the 21-byte
'     setne/movzx/cmp emission (10.3); the direct compare form is 9 bytes shorter.
'  2. The active-gadget test comes BEFORE the `If found` block and ends in a Continue:
'     cmp ebx,[g_activeGadget] / jne +7 / mov edi,1 / jmp <loop-next>. Ghidra hoists this
'     to the bottom of the loop, which is the wrong source order and 2 bytes short.
'  3. The tail is an If-BLOCK (`If first <> Null` ... End If), not the early-return
'     `If first = Null Then Return 0` -- exactly the per-function guard-shape choice
'     described in 10.9. Both spell 539 in total only with 1 and 2 also correct.
'  Note the mixed Null idiom inside one function: the `Not first` truth test at the top of
'  the loop and the direct `first <> Null` compare at the bottom. That is what the original
'  does; do not normalise them to one form.
'!Global g_activeGadget:TGadget
'!Global g_activeScreen:TScreen
'!Global g_screenFlag:Int
	Method TabToGadget:Int()
		Local first:TGadget = Null
		Local found:Int = 0
		For Local g:TGadget = EachIn Self.GetGadgetList()
			If g.alive = 0 Or g.hidden Then Continue
			If Not TButton(g) And Not TInputBox(g) And Not TCombo(g) And Not TTable(g) Then Continue
			LogLine(g.name)
			If Not first Then first = g
			If g = g_activeGadget
				found = 1
				Continue
			End If
			If found
				g_activeScreen.SetActiveGadget(g.name)
				If TInputBox(g) Then TInputBox(g).gettinginput = 1
				g_screenFlag = 0
				FlushKeys
				Return 0
			End If
		Next
		If first <> Null
			Self.SetActiveGadget(first.name)
			If TInputBox(first) Then TInputBox(first).gettinginput = 1
			g_screenFlag = 0
			FlushKeys
			Return 0
		End If
	End Method
