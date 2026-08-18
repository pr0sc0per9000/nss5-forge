' TScreen_EditCompetition.ButtonQuit
' VA 0x005320b9   60 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (60/60, original length from Ghidra's inventory)
' assumptions: module Global 0x00c6571c declared String (it is the screen the editor was
'              entered from; globals_final calls it an Int on "read-only dword" evidence,
'              but it is the left operand of a _bbStringCompare at 0x004a6a30 -- so String).
'              Class-table slots: 0x00c658f0 = TScreen_EditCompetition+0x4c UpdateComp,
'              0x00c65c3c = TScreen_ContinentalComps+0x34 SetUpScreen,
'              0x00c656f0 = TScreen_Competitions+0x34 SetUpScreen.
'              String literal "continentalcomps" read out of NSS5.exe at 0x00c837a4.
' NOTE: this is a Select, not If/ElseIf -- the If/Else form is 58 bytes. The subject is
'       loaded once (`A1 1C 57 C6 00  mov eax,[global]`), which is the Select tell.
	Function ButtonQuit:Int()
		'!Global g_editcomp_from:String
		TScreen_EditCompetition.UpdateComp()
		Select g_editcomp_from
			Case "continentalcomps"
				TScreen_ContinentalComps.SetUpScreen()
			Default
				TScreen_Competitions.SetUpScreen()
		End Select
	End Function
