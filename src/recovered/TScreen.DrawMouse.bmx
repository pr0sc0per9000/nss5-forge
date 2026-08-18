' TScreen.DrawMouse
' VA 0x005111B2   133 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C6173C Int (visible flag), 0x00C61738 TImage (cursor image),
' 0x00C61740/0x00C61744 Float (cursor x/y), 0x00C61CF8 Object (drag payload; Null when
' nothing is being dragged). "FFFFFF" read out of .rdata at 0x00C5D680.
' SetDrawStateHex is the recovered module Function at 0x00506456.
' Branch sense is load-bearing: the original is `cmp [g],bbNullObject / je`, i.e. the
' NOT-Null arm comes first. Writing `If g = Null` first inverts the jump and diverges at
' byte 49.
' ############################################################################
' # NAME FIX 2026-08-15 -- same slot, two names. Behaviour bug, not a rewrite.#
' ############################################################################
' This body declared the cursor position as g_screen_mousex/g_screen_mousey, but
' THIS FILE'S OWN HEADER (above) records those slots as 0x00C61740/0x00C61744 --
' which is exactly what src/recovered/TScreen.GetInput.bmx calls
' g_screen_float03/g_screen_float04 ("scaled mouse xy", its line 28), and what
' src/recovered/TGadget.MouseOver.bmx reads to decide whether the pointer is over
' a gadget. One slot, two recovered names.
'
' Verified alone in a probe, that is invisible. In the ASSEMBLED program it is
' fatal: assemble.py emits one Global per distinct NAME, so the program gets two
' independent floats. GetInput writes g_screen_float03 every frame; DrawMouse read
' g_screen_mousex, which nothing ever writes. The cursor was therefore drawn at
' (0,0) on every frame -- present, but pinned to the top-left corner.
'
' Measured, not inferred: grepping src/recovered/ + src/recovered_module/ for any
' assignment to g_screen_mousex returns NOTHING, while g_screen_float03 is written
' in TScreen.GetInput and read in TGadget.MouseOver. Clicking was never affected --
' it goes through MouseOver on the correct slot -- which is why hit-testing worked
' while the pointer appeared stuck.
'
' STILL OPEN, deliberately not touched here: TGadget.UpdateToolTip.bmx line 9
' annotates g_screen_mousex as 0x00C61724 (and mousey as 0x00C61728) -- different
' addresses from this file's 0x00C61740/44, same names. One of the two annotations
' is wrong. Tooltip X positioning reads it (`lbl_ToolTip.x = tx - g_screen_mousex`),
' so if 0x00C61724 is the wrong address, tooltips are offset by the mouse position.
' Left alone because the evidence here only settles THIS file; flagged so the
' contradiction is not lost.
'
' Expect scripts/reverify.py to flag this body. A Global rename changes which slot
' the emitted reference points at, so it is a real change, not cosmetic -- that is
' the regression suite working, not a nuisance.
	Function DrawMouse:Int()
		'!Global g_screen_showmouse:Int
		'!Global g_screen_dragobj:Object
		'!Global g_screen_cursor:TImage
		'!Global g_screen_float03:Float
		'!Global g_screen_float04:Float
		If g_screen_showmouse <> 0
			SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
			If g_screen_dragobj <> Null
				DrawImage g_screen_cursor, g_screen_float03, g_screen_float04, 1
				SetAlpha 1.0
			Else
				DrawImage g_screen_cursor, g_screen_float03, g_screen_float04, 0
			EndIf
		EndIf
	End Function
