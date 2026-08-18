' TScreen_Interview.Fail
' VA 0x0057BE24   169 bytes   vtable slot 0x4C   sig ()i
' byte-identical vs NSS5.exe (169/169, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C6B850 TSound, 0x00C6F090 TChannel (the two PlaySound operands),
' 0x00C5B1C8 TBitmapFont (typed from its construction site), 0x00C6EFE4/0x00C6EFE8 Int
' (graphics width/height -- the shift pattern is signed /2), 0x00C6CDE4 TButton (typed from
' its construction site), 0x00C6F1B8 TImage, 0x00C6F028 TProfile.
' Indirect calls resolved: PTR_FUN_00C6B264 = TScreenMessage class table + slot 0x30 =
' TScreenMessage.Create(i,i,$,i,:TBitmapFont,:TImage,f,$); slot 0x90 on the TButton global is
' TButton.SetIcon(:TImage); slot 0x58 is TGadget.Show() (INHERITED -- TButton has no 0x58);
' slot 0xC0 on the TProfile global is TProfile.UpdateRelationship(i,i).
' "Fail!" / "FFFFFF" read out of .rdata at 0x00C91604 / 0x00C5D680; 0x004C5549 is the
' recovered module Function GetText.
'
' Verified from scratch with the eight '!Global pragmas below -> MATCH
' 169/169, reloc_masked=15. A BUILD_FAIL without them is a harness limitation
' (it cannot bind a Global from prose alone), not a body defect.
	Function Fail:Int()
		'!Global g_interview_failsound:TSound
		'!Global g_interview_channel:TChannel
		'!Global g_engine_gfxw:Int
		'!Global g_engine_gfxh:Int
		'!Global g_engine_font:TBitmapFont
		'!Global g_interview_button:TButton
		'!Global g_negotiate_icon:TImage
		'!Global g_contractoffer_profile:TProfile
		PlaySound(g_interview_failsound, g_interview_channel)
		TScreenMessage.Create(g_engine_gfxw/2, g_engine_gfxh/2, GetText("Fail!"), 1000, g_engine_font, Null, 1.0, "FFFFFF")
		g_interview_button.SetIcon(g_negotiate_icon)
		g_interview_button.Show()
		g_contractoffer_profile.UpdateRelationship(7, -5)
	End Function
