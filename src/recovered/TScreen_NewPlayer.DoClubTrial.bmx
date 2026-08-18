' TScreen_NewPlayer.DoClubTrial
' VA 0x00524B34   786 bytes   class-table slot 0x5C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (786/786, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=67)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C6F028 TProfile  g_profile        (globals_final construction/high; used elsewhere,
'                                            e.g. TScreen_NewPlayer.ButtonPlay)
'    0x00C64228 TCombo    g_np_comboclub   (globals_final construction, confirmed name from
'                                            TScreen_NewPlayer.ButtonPlay's header)
'    0x00C81794 Int       g_screen_newplayer_int17  (flag: "have we shown CMESSAGE_TRIAL yet")
'    0x00C64218 Int       g_screen_newplayer_int04  (written elsewhere by TTraining.SetUpTraining;
'                                            read-only here -- nonzero means SetUpTraining bailed
'                                            out and the caller must return to the screen)
'  Fields: TCombo slot 0xC0 = GetSelectedItemId()i.  TClub/TBase_Team .labelshortname +0x20.
'    TProfile .myclub :TClub +0x1D0, .pace +0xA4, .shooting +0xA8, .passing +0xAC,
'    .tackling +0xB0, .heading +0xB4, .dribbling +0xB8, .flair +0xBC, .energy :Float +0x15C.
'  Slots resolved: TContractOffer+0x58 = GetInitialClub(i):TClub, TContractOffer+0x3C =
'    GetOffer(:TClub):TContractOffer, TTraining+0x30 = SetUpTraining(i)i, TScreen+0x94 =
'    DoMessage($,i,i)i, TScreen_NewPlayer+0x34 = SetUpScreen()i (sibling static, written
'    unqualified), TScreen_ContractOffer+0x34 = SetUpScreen(:TContractOffer,()i,()i)i.
'  BRL: 0x004A75B0 _bbStringReplace, 0x004C5549 GetText (module Function, ($)$ -- consumes
'    only the top-of-stack push; the extra pushes before it belong to the FOLLOWING Replace
'    call, per codegen-patterns' warning that Ghidra merges argument lists across calls).
'  Literal 0x00C81848 read directly from NSS5.exe's data section: 100.0 (energy reset).
'  Literals (address only, contents not proof-read this pass): "CMESSAGE_TRIAL",
'    "CMESSAGE_TRIALSUCCESS", "CMESSAGE_TRIALFAIL", "$clubname".
' SHAPE NOTES (each measured)
'  * `TContractOffer.GetOffer(c)` is called NESTED inside the SetUpScreen(...) argument list,
'    not via a `Local o:TContractOffer =` temporary -- here (unlike TScreen_MyContract.
'    ButtonOffer) the original pushes the two `()i` function-pointer arguments BEFORE calling
'    GetOffer, which only a nested call reproduces (codegen-patterns 16.2's OTHER case).
'  * The pace+dribbling+tackling+passing+shooting+heading+flair<20 test is a solo relational
'    condition guarding two genuinely different branches (codegen-patterns solo-If/Else
'    swap rule): to reproduce the original's fallthrough=SUCCESS / jump-target=FAIL layout the
'    source must be written with the NEGATED comparison (`>= 20`) and the branches swapped from
'    the naive reading, i.e. `If sum >= 20 Then <success msg> Else <fail msg + Return 0>`.
'  * The energy/myclub/GetOffer/SetUpScreen tail sits OUTSIDE the If/Else, physically placed by
'    bcc AFTER the FAIL block; SUCCESS reaches it by falling through the EndIf, FAIL never
'    reaches it because its own branch has an explicit early `Return 0`.
'  * The seven `TTraining.SetUpTraining(id)` calls (ids 1,2,4,6,9,7,3 -- 5 and 8 skipped, and
'    NOT in ascending order for the last two) are a flat sequence of early returns
'    (`If g_screen_newplayer_int04 <> 0 Then SetUpScreen() ; Return 0`), not a nested cascade --
'    Ghidra's decompiler re-nests consecutive early returns into an if/else pyramid, but the
'    disassembly is a flat run of `cmp/je/call/jmp`.
'  * The pace/dribbling/tackling/passing/heading/shooting/flair zeroing block and the later
'    summation read the SAME seven fields in two DIFFERENT orders (heading before shooting when
'    zeroing; shooting before heading when summing) -- reproduced exactly, not normalised.
	'!Global g_profile:TProfile
	'!Global g_np_comboclub:TCombo
	'!Global g_screen_newplayer_int17:Int
	'!Global g_screen_newplayer_int04:Int
	Function DoClubTrial:Int()
		Local c:TClub = TContractOffer.GetInitialClub(g_np_comboclub.GetSelectedItemId())
		If g_screen_newplayer_int17 = 0
			TScreen.DoMessage(GetText("CMESSAGE_TRIAL").Replace("$clubname", c.labelshortname), 0, 0)
			g_screen_newplayer_int17 = 1
		EndIf
		g_profile.myclub = c
		g_profile.pace = 0
		g_profile.dribbling = 0
		g_profile.tackling = 0
		g_profile.passing = 0
		g_profile.heading = 0
		g_profile.shooting = 0
		g_profile.flair = 0
		TTraining.SetUpTraining(1)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		TTraining.SetUpTraining(2)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		TTraining.SetUpTraining(4)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		TTraining.SetUpTraining(6)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		TTraining.SetUpTraining(9)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		TTraining.SetUpTraining(7)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		TTraining.SetUpTraining(3)
		If g_screen_newplayer_int04 <> 0
			SetUpScreen()
			Return 0
		EndIf
		If g_profile.pace + g_profile.dribbling + g_profile.tackling + g_profile.passing + g_profile.shooting + g_profile.heading + g_profile.flair >= 20
			TScreen.DoMessage(GetText("CMESSAGE_TRIALSUCCESS").Replace("$clubname", c.labelshortname), 0, 0)
		Else
			TScreen.DoMessage(GetText("CMESSAGE_TRIALFAIL").Replace("$clubname", c.labelshortname), 0, 0)
			Return 0
		EndIf
		g_profile.energy = 100.0
		g_profile.myclub = Null
		TScreen_ContractOffer.SetUpScreen(TContractOffer.GetOffer(c), TScreen_NewPlayer.SetUpScreen, TProfile.StartNewGame)
		Return 0
	End Function
