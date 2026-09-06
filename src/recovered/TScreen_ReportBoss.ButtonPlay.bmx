' TScreen_ReportBoss.ButtonPlay
' VA 0x005623D3   34 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Global 0x00C6F028 :TProfile -- the profile, the slot 138 other bodies force
'   unanimously (global_address_map.tsv:1928, CERTAIN across 186). The call at 0x005623E4
'   is `call dword ptr [eax + 0x6c]`, and slot 0x6c is TProfile.NextPlayButton.
'
' THE TYPE IS THE WHOLE POINT HERE, and the byte oracle cannot check it. Slot 0x6c is
' NextPlayButton on TProfile and UpdateTeamMateId_Human on TPlayer, so `call [eax+0x6c]`
' assembles identically either way and a TPlayer spelling of this body also MATCHes at
' 34/34 -- while reading a Global that nothing writes, because the profile's writers all
' spell the slot g_profile. Read the address, not the match.

	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		TScreen_GameMenu.SetUpScreen()
		g_profile.NextPlayButton()
	End Function
