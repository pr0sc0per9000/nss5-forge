' TScreen_Interview.Success
' VA 0x0057BD61   195 bytes
' byte-identical vs NSS5.exe (195/195, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_sound_success:TSound
'!Global g_channel:TChannel
'!Global g_font:TBitmapFont
'!Global g_screenw:Int
'!Global g_screenh:Int
'!Global g_button_interview:TButton
'!Global g_icon_tick:TImage
'!Global g_profile:TProfile
PlaySound(g_sound_success, g_channel)
TScreenMessage.Create(g_screenw / 2, g_screenh / 2, GetText("Success!"), 1000, g_font, Null, 1.0, "FFFFFF")
g_button_interview.SetIcon(g_icon_tick)
g_button_interview.Show()
g_profile.UpdateRelationship(7, 5)
g_profile.interviewskill = g_profile.interviewskill + 1
