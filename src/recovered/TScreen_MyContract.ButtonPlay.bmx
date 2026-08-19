' TScreen_MyContract.ButtonPlay
' VA 0x00554d94   138 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c6f028 is g_profile:TProfile, and the four Globals
' 0x00c67da0/da4/da8/dac are TCombo. The four target field offsets 0x138/0x13c/0x140/0x144
' are TProfile.desiredcontinentid/desirednationid/desiredleagueid/desiredclubid.
'
' WHY 0x00c6f028 IS g_profile:TProfile AND NOT g_player:TPlayer. A TPlayer spelling with the
' fields lastframetime/imageframenumber/skincol/haircol has the same offsets and the same Int
' width, so the emitted bytes are identical and the oracle cannot discriminate -- but the type
' is settled against this exact address in extracted/globals_type_overrides.tsv:
' construction site 0x004BB9E2 is `push 0x00C6A4C0 (TProfile classtable); call bbObjectNew`,
' and TPlayer's instance is 396 bytes, too small for a +0x1A4 field written through the same
' slot elsewhere. Four TCombo selections feeding four `desired*` ids is also what a contract
' screen's Play button does; four combo boxes setting skin and hair colour is not. The TPlayer
' spelling also makes the assembled program uncompilable (g_player declared TPlayer here and
' TProfile by TScreen_Dilemma.SetUpScreen -> `Identifier 'relationgirlfriend' not found`).
	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		'!Global g_cmb1:TCombo
		'!Global g_mc_cmb_nation:TCombo
		'!Global g_cmb3:TCombo
		'!Global g_mc_cmb_club:TCombo
		g_profile.desiredcontinentid = g_cmb1.GetSelectedItemId()
		g_profile.desirednationid = g_mc_cmb_nation.GetSelectedItemId()
		g_profile.desiredleagueid = g_cmb3.GetSelectedItemId()
		g_profile.desiredclubid = g_mc_cmb_club.GetSelectedItemId()
		TScreen_Home.SetUpScreen()
	End Function
