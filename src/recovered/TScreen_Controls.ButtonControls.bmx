' TScreen_Controls.ButtonControls
' VA 0x005238c0   140 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (140/140, original length from Ghidra's inventory)
' ASSUMPTIONS: FUN_00438290 is JoyCount() -- it calls joyGetNumDevs/joyGetPos and the
' oracle learned it as _JoyCount on this match. Two Int module Globals. TScreen slot 0x94 =
' DoMessage($,i,i); the tail call is TScreen_Controls+0x40 = RefreshButtons, a sibling
' Function (no Type prefix). The GetText key is a masked address; its VALUE is unproven.
'
' NOTE: this is a Select, not If/ElseIf -- the subject is loaded ONCE into eax
' (A1 A8 D1 C5 00 / 83 F8 00) and every Case compares against that register. The If/ElseIf
' form re-reads the Global for each test and comes out 143 bytes. Case 0 is empty and is
' what emits the leading "cmp eax,0 / je end" that Ghidra renders as "if (x != 0)".
' harness mode=reloc, 13 addresses masked.
	Function ButtonControls:Int()
		'!Global g_joycount:Int
		'!Global g_ctrlstate:Int
		g_joycount = JoyCount()
		g_ctrlstate :+ 1
		Select g_ctrlstate
			Case 0
			Case 1
				If g_joycount = 0
					TScreen.DoMessage(GetText("settings_JOYNOTFOUND"), 0, 0)
					g_ctrlstate = 0
				End If
			Case 2
				If g_joycount < 2 Then g_ctrlstate = 0
			Default
				g_ctrlstate = 0
		End Select
		RefreshButtons()
	End Function
