' TPlayer.RedCard
' VA 0x004f546d   163 bytes   vtable slot 0xe0   sig ()i
' byte-identical vs NSS5.exe (163/163, original length from Ghidra's inventory)
' assumes: TTeam Global (globals_final says TKit, but field +8 is TTeam.id); early-return guard; 0x004a7410 = Lower()
	Method RedCard:Int()
		'!Global g_team1:TTeam
		'!Global g_redcards_home:Int
		'!Global g_redcards_away:Int
		'!Global g_msgtime:Int
		'!Global g_font:TBitmapFont
		'!Global g_msgimg:TImage
		If Self.selectionno = 0 Then Return 0
		If Self.teamid = g_team1.id
			g_redcards_home :+ 1
		Else
			g_redcards_away :+ 1
		EndIf
		Self.AddStat(10, 0, 0, 0, 0)
		TScreenMessage.Create(0, 0, Lower(GetText("Red Card!")), g_msgtime, g_font, g_msgimg, 2.0, "FFFFFF")
		Self.selectionno = 50
	End Method
