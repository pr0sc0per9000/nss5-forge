' TScreen_NewPlayer.DoClubTrial
' VA 0x00524B34   786 bytes   class-table slot 0x5C   sig ()i   KIND=Function (static)
'
' THIS PASS: the file as inherited was 100% prose research notes -- not one
' statement line survived stripping the leading `'`. assemble.py's load_recovered()
' treats a file with no Method/Function wrapper AND no non-comment text as a
' legitimate empty body ("Nothing but comments and pragmas" -- codegen-patterns 3d),
' so this compiled to the default 14-byte empty stub. The 786-byte/74.4%-agreement
' status/score/TScreen_NewPlayer.DoClubTrial.txt report on disk is stale: it was
' scored against an EARLIER build, from before the body was wiped down to notes, and
' its first-difference bytes (offset 6: original loads Global 0x00C64228, that build
' loaded 0x00C9C76C instead -- a plain wrong-Global bug in whatever body produced it)
' do not describe the current file, which had no code to diff at all.
'
' FIX: wrote a real body from extracted/decomp/TScreen_NewPlayer.DoClubTrial@00524b34.c,
' cross-checked line by line against a now-existing BYTE-IDENTICAL implementation of
' this exact function at src/recovered/TScreen_NewPlayer.DoClubTrial.bmx (786/786) --
' the strongest possible sibling, since it is not just the same Type but the same
' Method. Reproduced verbatim from there (its own header has the full derivation);
' independently re-checked the two points its notes flagged as resolved-elsewhere:
'   * FUN_004c5549 is the recovered module Function GetText(a0:String):String
'     (src/recovered_module/GetText.bmx, ($)$, argbytes=4/1 arg per call_arity.tsv).
'     The decompiler's apparent 5-argument call is Ghidra merging THREE separate call
'     sites' pushes into one printed call -- confirmed against call_sites.tsv for this
'     VA: 0x524b70 GetText argbytes=4 (1 arg), 0x524b79 _bbStringReplace argbytes=12
'     (3 args: subject, find, replace), 0x524b82 DoMessage argbytes=12 (3 args) --
'     i.e. GetText(key).Replace("$clubname", club.labelshortname) feeding straight
'     into DoMessage(text, 0, 0), never a single 5-arg call.
'   * TScreen.DoMessage is a static Function (object_model.json TScreen offset
'     148=0x94, sig ($,i,i)i) -- no Self needed, so the 3 pushed args are the whole
'     call, resolving the "no visible Self" question the notes had left open.
'   * TCombo slot 0xC0 = GetSelectedItemId()i; TContractOffer+0x58 = GetInitialClub
'     (i):TClub is itself a static Function taking that selected id (object_model.json
'     confirms both). TClub/TBase_Team field +0x20 = labelshortname:String.
'   * TProfile (the Global at 0x00C6F028, named g_profile elsewhere in this Type,
'     e.g. TScreen_NewPlayer.ButtonPlay): myclub:TClub +0x1D0, energy:Float +0x15C,
'     pace/shooting/passing/tackling/heading/dribbling/flair Ints at
'     0xA4/0xA8/0xAC/0xB0/0xB4/0xB8/0xBC (object_model.json).
'   * Literal at 0x00C81848 read directly out of NSS5.exe's data section: 100.0.
'   * Message keys read with harness.read_string: 0xC817B8 "CMESSAGE_TRIAL",
'     0xC817E0 "CMESSAGE_TRIALSUCCESS", 0xC81818 "CMESSAGE_TRIALFAIL", and the
'     Replace placeholder token 0xC81798 "$clubname".
' module Globals assumed (names ours where unconfirmed, types load-bearing):
'   Global g_profile:TProfile           ' 0x00C6F028
'   Global g_np_comboclub:TCombo        ' 0x00C64228 (confirmed name from
'                                        '   TScreen_NewPlayer.ButtonPlay's header)
'   Global g_screen_newplayer_int17:Int ' 0x00C81794 -- "have we shown CMESSAGE_TRIAL
'                                        '   yet" flag
'   Global g_screen_newplayer_int04:Int ' 0x00C64218 -- written by
'                                        '   TTraining.SetUpTraining; read-only here
' SHAPE (measured, per the verified sibling):
'   * the seven TTraining.SetUpTraining(id) calls (ids 1,2,4,6,9,7,3, in that exact
'     order) are a FLAT run of early returns, not a nested If/ElseIf cascade --
'     Ghidra re-nests consecutive early returns into a pyramid, but the disassembly
'     is a flat cmp/je/call/jmp repeated seven times.
'   * the pace+dribbling+tackling+passing+shooting+heading+flair sum test is written
'     with the NEGATED comparison (`>= 20`) and swapped branches vs. the naive
'     reading, to reproduce the original's fallthrough=SUCCESS / jump-target=FAIL
'     layout (codegen-patterns solo-If/Else swap rule).
'   * the energy/myclub/GetOffer/SetUpScreen tail sits OUTSIDE the If/Else, reached
'     only by the SUCCESS fallthrough; FAIL has its own early Return 0.
'   * TContractOffer.GetOffer(c) is called NESTED inside SetUpScreen(...)'s own
'     argument list, not through a temporary Local.
'!Global g_profile:TProfile
'!Global g_np_comboclub:TCombo
'!Global g_screen_newplayer_int17:Int
'!Global g_screen_newplayer_int04:Int
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
