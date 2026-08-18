' TEngine.CheckShootOutComplete
' VA 0x004D780C   642 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0xf0
' ASSUMPTIONS
'   0x00C5B22C g_engine_fixture:TFixture -- globals_final guesses TPlayer; +0x34/+0x38 are
'     TFixture.penscore1/penscore2, which fixes the type (name ours).
'   0x00C5B238 g_engine_int25:Int (the penalty-attempt counter).
'   Both dispatches are Selects, not If/ElseIf: the subject is evaluated once (one idiv for
'     `Mod 2`, one global load for the outer) and every Case compare is emitted back to back
'     before any body -- codegen-patterns 10.2. Cases 0..5 have genuinely empty bodies and
'     are separate Cases (each has its own jump target), not `Case 0,1,2,3,4,5`.
'   The Default arm holds a nested Select on the local, with an empty Case 1.
'   Literals "CheckShootOutComplete:" " att:" "fixture.penscore1:" "fixture.penscore2:"
'     read out of the exe with harness.read_string.
'   LogLine is the recovered module Function at 0x00505B91.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_engine_int25:Int
'!Global g_engine_fixture:TFixture
Local t:Int = 0
Select g_engine_int25 Mod 2
	Case 0
		t = 2
	Case 1
		t = 1
End Select
LogLine("CheckShootOutComplete:" + String(g_engine_int25) + " att:" + String(t))
LogLine("fixture.penscore1:" + String(g_engine_fixture.penscore1))
LogLine("fixture.penscore2:" + String(g_engine_fixture.penscore2))
Select g_engine_int25
	Case 0
	Case 1
	Case 2
	Case 3
	Case 4
	Case 5
	Case 6
		If g_engine_fixture.penscore1 - g_engine_fixture.penscore2 > 2 Then Return 1
		If g_engine_fixture.penscore2 - g_engine_fixture.penscore1 > 2 Then Return 1
	Case 7
		If g_engine_fixture.penscore1 - g_engine_fixture.penscore2 > 2 Then Return 1
		If g_engine_fixture.penscore2 - g_engine_fixture.penscore1 > 1 Then Return 1
	Case 8
		If g_engine_fixture.penscore1 - g_engine_fixture.penscore2 > 1 Then Return 1
		If g_engine_fixture.penscore2 - g_engine_fixture.penscore1 > 1 Then Return 1
	Case 9
		If g_engine_fixture.penscore1 - g_engine_fixture.penscore2 > 1 Then Return 1
		If g_engine_fixture.penscore2 - g_engine_fixture.penscore1 > 0 Then Return 1
	Case 10
		If g_engine_fixture.penscore1 <> g_engine_fixture.penscore2 Then Return 1
	Default
		Select t
			Case 1
			Case 2
				If g_engine_fixture.penscore1 <> g_engine_fixture.penscore2 Then Return 1
		End Select
End Select
Return 0
