' TProfile.StartNewGame
' VA 0x005660eb   28 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (28/28, original length from Ghidra's inventory)
' This file is the whole of the TPlayer side of the g_contractoffer_tplayer conflict,
' and that reading is wrong twice over:
'   * 0x00C6F028 is a TProfile, not a TPlayer. Its construction site at 0x004BB9E2 is
'     `push 0x00C6A4C0; call bbObjectNew` and 0x00C6A4C0 is TProfile's class table.
'     TPlayer is impossible on size alone: instance_size 396 cannot hold the +0x1A4 field
'     that TContractOffer.EraseInterestedClubs writes through this same Global.
'     The old note ("only TPlayer has slots 0x30/0x34/0x3C/0x40") is the unsound
'     uniqueness claim codegen-patterns 11.2 warns about -- 143 Types share those slots.
'   * slot 0x48 is therefore TProfile.StartCareer()i, not TPlayer.Update()i.
'     `call [eax+0x48]` is the same three bytes either way, which is exactly why the
'     wrong body verified alone.
' Renamed to the corpus-majority name for this slot, g_profile (6 other files already
' use it for 0x00C6F028).
	Function StartNewGame:Int()
		'!Global g_profile:TProfile
		g_profile.StartCareer()
	End Function
