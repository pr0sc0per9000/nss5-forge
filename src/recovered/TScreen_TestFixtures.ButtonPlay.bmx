' TScreen_TestFixtures.ButtonPlay
' VA 0x00539A7E   120 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (120/120, original length from Ghidra's inventory)
' Assumptions: module Global 0x00c6f028 = g_profile:TProfile (typed from 3 construction
' sites, confidence high); TProfile.date is field +0x10, TMyDate slot 0x54 = GetYear,
' TProfile slot 0x54 = Play(i); class-table pointer 0x00c66710 =
' TScreen_TestFixtures.SetUpScreen (slot 0x34). 0x005B4721 is the KeyDown/MouseDown alias
' set -- KeyDown is the member that fits (162 = KEY_LCONTROL).
' The SetUpScreen call really is emitted twice, once per branch.
	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		Local y:Int = g_profile.date.GetYear()
		If KeyDown(162)
			Repeat
				g_profile.Play(0)
			Until g_profile.date.GetYear() > y
			TScreen_TestFixtures.SetUpScreen()
		Else
			g_profile.Play(0)
			TScreen_TestFixtures.SetUpScreen()
		End If
	End Function
