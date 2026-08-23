' TBall.CheckSideLines -- VA 0x004CA8A4, 491 bytes
' VA 0x004ca8a4   491 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (491/491, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe (491/491, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=19).
'
' ASSUMPTIONS (all load-bearing ones listed):
'  * Module Globals -- names are OURS, types are the assumption:
'      g_matchstate:Int        0x00C5B1FC  (globals_final says Int, type_source=verified,
'                                           hand-verified in globals_corrections.tsv)
'      g_hometeam:TTeam      0x00C5B218  -- globals_final says "TKit  CONFLICT TKit=2;TTeam=1".
'                                             IT IS TTeam.  The code reads field +8 and compares
'                                             it to TPlayer.teamid (an Int).  TKit+8 is
'                                             pixmap:TPixmap (an object) -- that comparison would
'                                             not even compile.  TTeam+8 is id:Int.  Field access
'                                             is a direct offset so codegen is identical either
'                                             way; the Type is chosen on semantics, not on bytes.
'      g_pitchhalfwidth:Int    0x00C5D634
'      g_pitchmargin:Int       0x00C5A4C8
'      g_pitchhalfheight:Int   0x00C5D638
'    All three pitch Globals are bare dword loads with no refcount traffic -> Int (guide 11.2).
'  * call [0x00C5BAA0] is a class-table interior, not a Global: TEngine+0x70 =
'    SetUpSetPiece (i,i,i,i)i at 0x004D2F01 (globals_classtable_slots.tsv + vtable_map.tsv).
'    Written as the ordinary cross-Type static call TEngine.SetUpSetPiece.
'  * slot 0x160 on the TPlayer local is TPlayer.GetShootingDirection ()i at 0x004FADCB.
'  * Local names (p, t) are ours; both are register-allocated (ecx, ebx) and carry no
'    refcount traffic in the original either.
'
' Comparison forms were read off the cmp/setcc, not off Ghidra (guide 10.1):
'   Self.x > half+margin   ->  fucompp/setbe (the NEGATED test) + jne-over-body
'   Self.x < -half-margin  ->  neg eax / sub eax,[margin] then setae
' Every branch ends in an explicit Return 0 (mov eax,0 / jmp epilogue), and the two
' GetShootingDirection tests are If/Else, not early returns.
Method CheckSideLines:Int()
	'!Global g_matchstate:Int
	'!Global g_hometeam:TTeam
	'!Global g_pitchhalfwidth:Int
	'!Global g_pitchmargin:Int
	'!Global g_pitchhalfheight:Int
	If Self.active = 0 Then Return 0
	If g_matchstate <> 1 And g_matchstate <> 10 Then Return 0
	Local p:TPlayer = Self.lasttouchedby
	If Self.controlledby <> Null Then p = Self.controlledby
	If Not p Then Return 0
	Local t:Int = 1
	If g_hometeam.id = p.teamid Then t = 2
	If Self.x > g_pitchhalfwidth + g_pitchmargin
		TEngine.SetUpSetPiece(3, t, 0, 0)
		Return 0
	EndIf
	If Self.x < -g_pitchhalfwidth - g_pitchmargin
		TEngine.SetUpSetPiece(3, t, 0, 0)
		Return 0
	EndIf
	If Self.y > g_pitchhalfheight + g_pitchmargin
		If p.GetShootingDirection() = 1
			TEngine.SetUpSetPiece(6, t, 0, 0)
			Return 0
		Else
			TEngine.SetUpSetPiece(5, t, 0, 0)
			Return 0
		EndIf
	EndIf
	If Self.y < -g_pitchhalfheight - g_pitchmargin
		If p.GetShootingDirection() = -1
			TEngine.SetUpSetPiece(6, t, 0, 0)
			Return 0
		Else
			TEngine.SetUpSetPiece(5, t, 0, 0)
			Return 0
		EndIf
	EndIf
End Method
