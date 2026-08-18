' TGadget.DrawHighlight
' VA 0x00513C5C   181 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (181/181, original length from Ghidra's inventory)
' TTable/TInputBox downcasts are recomputed (bcc does no CSE) exactly as the original does.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_screen_int03:Int

	Method DrawHighlight:Int()
		'!Global g_screen_int03:Int
		If hidden Then Return 0
		If g_screen_int03 Then Return 0
		If TTable(Self) And TTable(Self).activated Then Return 0
		If TInputBox(Self) And TInputBox(Self).gettinginput Then Return 0
		RenderHighlight()
	End Method
