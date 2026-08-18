' TProfile.UpdateBank
' VA 0x0056b669   183 bytes   vtable slot 0xfc   sig (i)i
' byte-identical vs NSS5.exe (183/183, original length from Ghidra's inventory)
' assumptions: FUN_004a6a30-neighbour FUN_004a7f60 is the Int Abs helper (bcc emits a call
'              for Abs on Int here, and the oracle masked it by name on both sides).
'              FUN_004c5549 is the recovered module Function GetText($)$.
'              Class-table slots: 0x00c61cc0 = TScreen+0x94 DoMessage($,i,i),
'              0x00c66914 = TScreen_GameMenu+0x38 UpdateTitlePanel.
'              String literal "CMESSAGE_NOTENOUGHCASH" read out of NSS5.exe at 0x00c87f24.
'              Self+0x150 is TProfile.CheckAchievement(i).
' NOTE: the thresholds are `>= 1000000 / 10000000 / 25000000`, emitted as
'       `cmp [edi+0x28],0xf4240 / jl`. Writing them as `> 999999` gives `cmp 0xf423f / jle`
'       -- same length, wrong bytes.
	Method UpdateBank:Int(a0:Int)
		If a0 < 0 And Self.bank < Abs(a0)
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"),0,0)
			Return 0
		Else
			Self.bank = Self.bank + a0
			If Self.bank >= 1000000 Then Self.CheckAchievement(57)
			If Self.bank >= 10000000 Then Self.CheckAchievement(58)
			If Self.bank >= 25000000 Then Self.CheckAchievement(59)
			TScreen_GameMenu.UpdateTitlePanel()
			Return 1
		EndIf
	End Method
