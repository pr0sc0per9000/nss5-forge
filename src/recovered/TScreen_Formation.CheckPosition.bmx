' TScreen_Formation.CheckPosition
' VA 0x0054ca33   580 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (STATIC method on TScreen_Formation), SIG ()i, class-table slot 0x44
' ASSUMPTIONS
'  * Module Globals -- NAMES ARE OURS, the declared TYPES are load-bearing:
'      g_screen_formation_selno:Int  0x00C677D4
'      g_profile:TProfile            0x00C6F028  (+0x30 position, +0x34 side)
'      g_playerteam:TTeam            0x00C677B0 -- globals_final has this as a bare
'        Object with no call-site typing.  The code does `mov eax,[g] / mov eax,[eax+0x24]`
'        and then dispatches slots 0x5C / 0x60 on the loaded field.  TTeam is the ONLY Type
'        in the object model with a :TFormation field at +0x24, and TFormation slot 0x5C is
'        GetPosFromSelectionNo(i)i, slot 0x60 GetSideFromSelectionNo(i)i -- both match the
'        one-Int-argument, Int-returning call shape exactly.
'  * TScreen_Formation.UpdatePosition is this Type's own class-table slot 0x54, so it is
'    written unprefixed (guide 3d).
'  * String literals read out of NSS5.exe: 0x00C89084 "CheckPosition:",
'    0x00C890AC "PosOK:".
'  * The `PosOK` branch ends in an explicit `Return 0` -- without it the body is 575 bytes;
'    the missing 5 are `mov eax,0 / jmp epilogue`.
'  * `for (i = 10; 0 < i; i--)` is `For i = 10 To 1 Step -1` (`add ebx,-1 / cmp ebx,1 / jge`).
	Function CheckPosition:Int()
		'!Global g_screen_formation_selno:Int
		'!Global g_profile:TProfile
		'!Global g_playerteam:TTeam
		LogLine("CheckPosition:" + g_screen_formation_selno)
		LogLine(TFormation.GetStringPosition(g_profile.position, g_profile.side))
		Local p:Int = g_playerteam.formation.GetPosFromSelectionNo(g_screen_formation_selno)
		Local s:Int = g_playerteam.formation.GetSideFromSelectionNo(g_screen_formation_selno)
		If p = g_profile.position And s = g_profile.side
			LogLine("PosOK:" + TFormation.GetStringPosition(p, s))
			Return 0
		Else
			For Local i:Int = 10 To 1 Step -1
				Local p2:Int = g_playerteam.formation.GetPosFromSelectionNo(i)
				Local s2:Int = g_playerteam.formation.GetSideFromSelectionNo(i)
				If p2 = g_profile.position And s2 = g_profile.side
					UpdatePosition(i)
					Return 0
				EndIf
			Next
			If g_profile.position = 5 Or g_profile.position = 1
				For Local i:Int = 10 To 1 Step -1
					If g_playerteam.formation.GetPosFromSelectionNo(i) = g_profile.position
						UpdatePosition(i)
						Return 0
					EndIf
				Next
			Else
				For Local i:Int = 10 To 1 Step -1
					Local p3:Int = g_playerteam.formation.GetPosFromSelectionNo(i)
					Local s3:Int = g_playerteam.formation.GetSideFromSelectionNo(i)
					If (p3 = 2 Or p3 = 3 Or p3 = 4) And s3 = g_profile.side
						UpdatePosition(i)
						Return 0
					EndIf
				Next
			EndIf
		EndIf
	End Function
