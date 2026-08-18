' TScreen.CheckInput
' VA 0x00511462   211 bytes   vtable slot 0x7c   sig ()i
' byte-identical vs NSS5.exe (211/211, original length from Ghidra's inventory)
' assumptions: Global 0x00C61CF8 declared TGadget (alive/hidden/fHit are read as direct
' fields at +0x38/+0x3C/+0x40), 0x00C6173C Int, 0x00C6171C TSound, 0x00C6F088 TChannel.
' Select, not If/ElseIf -- the three compares are emitted back to back (If/ElseIf is 205).
' The fHit function-pointer field is tested as a plain truth test (it is compared against
' the empty function 0x005B95D0 in the disassembly, per codegen-patterns 10.6).
	Method CheckInput:Int()
		'!Global g_mouseactive:Int
		'!Global g_selgadget:TGadget
		'!Global g_sndclick:TSound
		'!Global g_chanclick:TChannel
		Local inp:Int = Self.GetInput()
		Select inp
			Case 0
				If g_mouseactive <> 0 Then Self.MouseSelection()
			Case 5
				If g_selgadget <> Null And g_selgadget.fHit And g_selgadget.alive And g_selgadget.hidden = 0
					PlaySound(g_sndclick, g_chanclick)
					g_selgadget.fHit()
				EndIf
			Case 6
				Self.TabToGadget()
			Default
				Self.MoveSelection(inp)
		End Select
	End Method
