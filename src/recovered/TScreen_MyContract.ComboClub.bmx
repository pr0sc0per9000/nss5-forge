' TScreen_MyContract.ComboClub
' VA 0x005560B1   163 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (163/163, original length from Ghidra's inventory), harness mode=reloc
' Assumptions (module Globals -- names ours, declared types load-bearing):
'   * 0x00C6F028 : TProfile -- fields desiredcontinentid +0x138, desirednationid +0x13C,
'     desiredleagueid +0x140, desiredclubid +0x144.
'   * 0x00C67DA0 / A4 / A8 / AC : TCombo (globals_final, construction) -- slot 0xC0 =
'     TCombo.GetSelectedItemId()i.
'   * 0x00C6B814 -> class table TContractOffer + 0x5C  = TContractOffer.UpdateInterestedClubs()
'   * 0x00C68014 -> TScreen_MyContract + 0x3C = UpdateClubsInterestedLabel()
'   * 0x00C68040 -> TScreen_MyContract + 0x68 = UpdateOfferButtons()
'   * 0x00C88610 = 'ComboClub' -- the LogLine function-entry trace; the literal is this
'     function's own name, per the established LogLine convention.
	'!Global g_profile:TProfile
	'!Global g_mycon_cmb1:TCombo
	'!Global g_mycon_cmb2:TCombo
	'!Global g_mycon_cmb3:TCombo
	'!Global g_mycon_cmb4:TCombo
	Function ComboClub:Int()
		LogLine("ComboClub")
		g_profile.desiredcontinentid = g_mycon_cmb1.GetSelectedItemId()
		g_profile.desirednationid = g_mycon_cmb2.GetSelectedItemId()
		g_profile.desiredleagueid = g_mycon_cmb3.GetSelectedItemId()
		g_profile.desiredclubid = g_mycon_cmb4.GetSelectedItemId()
		TContractOffer.UpdateInterestedClubs()
		TScreen_MyContract.UpdateClubsInterestedLabel()
		TScreen_MyContract.UpdateOfferButtons()
	End Function
