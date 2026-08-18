' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TEngine.PauseEngine  -- KIND=Function (static method on TEngine), slot 0x100
' VA 0x004D7C67   260 bytes   sig ()i
' byte-identical vs NSS5.exe (260/260, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=33)
'
' ASSUMPTIONS
'  Module Globals declared (names are ours; types are load-bearing, all Int -- every
'  access is a bare mov/add with no refcount traffic):
'    0x00C746CC g_pauseticks : Int   (match clock at the moment of pausing)
'    0x00C6EFD4 g_matchclock : Int   (globals_final: 'verified', Int)
'    0x00C6EFD8 g_pausedms   : Int   (accumulated paused milliseconds)
'    0x00C5B1CC g_gamestate  : Int
'    0x00C746C8 g_prevstate  : Int
'    0x00C6F030 g_pauseclock : Int
'  Class-table slots resolved:
'    [0x00C67788] = TScreen_MatchPaused + 0x34 = SetUpScreen(:TImage)i -> called with Null
'    [0x00C5FAB0] = TPlayer + 0x164 = GetHumanPlayer():TPlayer
'    TJoy slot 0x3c = Clear()  (call on TPlayer.joy at +0x158)
'  Direct calls resolved:
'    0x004A4860 timeGetTime  -> MilliSecs()
'    0x004A7AC0 _bbStringFromInt / 0x004A7C20 _bbStringConcat -> "literal" + intGlobal
'    0x00505B91 -> LogLine (src/recovered_module/LogLine.bmx)
'    0x005071C3 -> FlushAllInput (src/recovered_module/FlushAllInput.bmx)
'  The two log string literals are pushed as absolute data addresses; the code bytes
'  show only that two distinct literals exist and that the first is concatenated with
'  g_prevstate. Their text comes from harness.read_string, per the note at the top.
'  The leading guard is an early return (cmp/jge/mov eax,0/jmp end), not an If-block.

	Function PauseEngine:Int()
		'!Global g_matchclock:Int
		'!Global g_pauseticks:Int
		'!Global g_pausedms:Int
		'!Global g_gamestate:Int
		'!Global g_prevstate:Int
		'!Global g_pauseclock:Int
		If g_matchclock < g_pauseticks + 100 Then Return 0
		g_matchclock = MilliSecs() - g_pausedms
		If g_gamestate = 1
			g_gamestate = g_prevstate
			LogLine("Unpause:" + g_prevstate)
			g_pausedms :+ (g_matchclock - g_pauseticks)
			g_matchclock = MilliSecs() - g_pausedms
			g_pauseclock = g_matchclock
		Else
			LogLine("Pause")
			g_pauseticks = g_matchclock
			g_prevstate = g_gamestate
			g_gamestate = 1
			TScreen_MatchPaused.SetUpScreen(Null)
		End If
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If p <> Null
			p.joy.kickenabled = 0
			p.joy.Clear()
		End If
		FlushAllInput()
	End Function
