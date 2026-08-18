' TFormation.SetUp
' VA 0x004d80c2   725 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x30
' ASSUMPTIONS
'   Global 0x00C5BB38..0x00C5BB58 are nine Floats (here g_form_*); direct evidence is the
'   fstp dword store of each ReadSettingFloat result.
'   Global 0x00C5BB6C..0x00C5BC20 are ten Strings (here g_sla_*); direct evidence is the
'   full retain/release traffic around each store (pattern 11.2), and GetText returns $.
'   Function names ReadSettingFloat/GetText are ours, both already verified module Functions.
' Literal strings read out of NSS5.exe with harness.read_string.
	Function SetUp:Int()
		'!Global g_form_height:Float
		'!Global g_form_width:Float
		'!Global g_form_widthnoball:Float
		'!Global g_form_depth:Float
		'!Global g_form_widepush:Float
		'!Global g_form_xshift:Float
		'!Global g_form_xshiftnoball:Float
		'!Global g_form_yshift:Float
		'!Global g_form_ymargin:Float
		'!Global g_sla_left:String
		'!Global g_sla_centre:String
		'!Global g_sla_right:String
		'!Global g_sla_goalkeeper:String
		'!Global g_sla_defender:String
		'!Global g_sla_defensivemid:String
		'!Global g_sla_midfielder:String
		'!Global g_sla_attackingmid:String
		'!Global g_sla_forward:String
		'!Global g_sla_substitute:String
		g_form_height = ReadSettingFloat("incbin::Inc/Engine.ini","formationheight",0,10000.0)
		g_form_width = ReadSettingFloat("incbin::Inc/Engine.ini","formationwidth",0,10000.0)
		g_form_widthnoball = ReadSettingFloat("incbin::Inc/Engine.ini","withoutballformationwidth",0,10000.0)
		g_form_depth = ReadSettingFloat("incbin::Inc/Engine.ini","formationdepth",0,10000.0)
		g_form_widepush = ReadSettingFloat("incbin::Inc/Engine.ini","wideplayerpush",0,10000.0)
		g_form_xshift = ReadSettingFloat("incbin::Inc/Engine.ini","formationxshift",0,10000.0)
		g_form_xshiftnoball = ReadSettingFloat("incbin::Inc/Engine.ini","withoutballformationxshift",0,10000.0)
		g_form_yshift = ReadSettingFloat("incbin::Inc/Engine.ini","formationyshift",0,10000.0)
		g_form_ymargin = ReadSettingFloat("incbin::Inc/Engine.ini","ymarginmultiply",0,10000.0)
		g_sla_left = GetText("sla_Left")
		g_sla_centre = GetText("sla_Centre")
		g_sla_right = GetText("sla_Right")
		g_sla_goalkeeper = GetText("sla_GoalKeeper")
		g_sla_defender = GetText("sla_Defender")
		g_sla_defensivemid = GetText("sla_DefensiveMid")
		g_sla_midfielder = GetText("sla_Midfielder")
		g_sla_attackingmid = GetText("sla_AttackingMid")
		g_sla_forward = GetText("sla_Forward")
		g_sla_substitute = GetText("sla_Substitute")
	End Function
