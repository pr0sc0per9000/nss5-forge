' TProfile.LoadSavedGame
' VA 0x005659F1   936 bytes   KIND=Function (static, no Self -- param_1 is a0), SIG=($)i,
' class-table slot 0x3C
' Body-only format: statements only; parameter is a0:String (the save filename, INCLUDING
' the ".sav" extension -- the sole caller, TScreen_MainMenu.ButtonLoadSaveFile
' (src/recovered/, VA 0x0051D54F), passes `s + ".sav"`).
' NOT YET byte-verified against NSS5.exe (recovered_pending -- assemble.py not run by this
' worker). Reconstructed from extracted/decomp/TProfile.LoadSavedGame@005659f1.c PLUS a
' fresh disassembly of the original bytes (scripts/harness.disasm_original) and
' extracted/callgraph_resolved.tsv's resolved call targets for this VA, because several of
' Ghidra's decompiled call sites merge/attribute argument lists misleadingly (see SHAPE
' NOTES below).
'
' ASSUMPTIONS
'   Module Globals (name + type from scripts/explain_global.py; ADDRESS is load-bearing):
'     g_savename:String  0x00C68BC8 (STRONG/3 bodies) -- assigned a0 verbatim at entry, the
'       usual retain-new/release-old/store Global-object-assignment codegen.
'     g_userpath:String  0x00C6E9A8 (CERTAIN/5 bodies, unanimous) -- the writable user data
'       directory; same slot/type/usage as TScreen_MainMenu.UpdateLoadTable's g_userpath.
'     g_profile:TProfile 0x00C6F028 (STRONG/142 bodies, the overwhelming winner for this
'       slot) -- the profile being loaded into. TProfile+0x34 (called on it here) is
'       TProfile.LoadProfile's own slot (src/recovered/TProfile.LoadProfile.bmx), which
'       fixes both the Global's identity and its type.
'   TProfile fields (offsets from TProfile.New.bmx's field-declaration order, all confirmed
'     by this function's own read/write pairs): nationid +0x1C, clubid +0x20, name +0x14,
'     saveversion +0xC, mynation:TNation +0x1CC, myclub:TClub +0x1D0, achievements:Int[]
'     +0x1BC (read only inside the not-reconstructed FUN_0058D90B, see below).
'   TMyStream extends the BRL TStreamWrapper: slot 0xA4 = SetStream(:TStream)i (its body
'     always `Return 0`, discarded here as a bare statement); TMyStream.New() has an empty
'     body (src/recovered/TMyStream.New.bmx), so `New TMyStream` takes no arguments.
'   The save's zip stream path is
'     "zipe::" + g_userpath + "Save/" + g_savename +
'     "::newstarsoccerfivesavefile::3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a"
'   -- byte-identical in shape to the equivalent expression already banked in
'   TScreen_MainMenu.UpdateLoadTable.bmx (same literal addresses 0x00C7B934 "zipe::" /
'   0x00C6EA20 "Save/" / 0x00C7ED24 the hash suffix, same hash text). FUN_004A7C20 is
'   _bbStringConcat (strictly 2 args, extracted/runtime_helpers.tsv); Ghidra folds this
'   whole 4-call chain's operands onto the one visible call
'   (`FUN_004a7c20(&c7b934,c6e9a8,&c6ea20,c68bc8,&c7ed24)` then 3 more `FUN_004a7c20(uVar3)`
'   calls) -- exactly the documented "Ghidra merges argument lists" trap; un-merged, by
'   left-associative pairing, it is the single expression above.
'   `If Not st Then ... Else ... EndIf` at machine offset +0x93 is the 21-byte `If Not x`
'   materialised-boolean idiom (`cmp ebx,0x5C9C80` / `setne al` / `movzx eax,al` / `cmp
'   eax,0` / `jne`), NOT a bare `If st Then` (that compiles to a direct 12-byte `cmp`/`je`
'   fused into the branch with no setne/movzx -- confirmed by the byte-identical
'   TBall.ClearAll@004c7736's `If g_balls <> Null` and by this project's own `If Not x`
'   convention note, e.g. src/recovered/TAchievement.LoadData.bmx: "Both Null-checks on the
'   TStream parameter use the 'If Not x' 21-byte form, not '= Null'" and
'   src/recovered/TClub.SaveMaster.bmx: "`cmp edx,0x5C9C80 / setne / movzx / cmp eax,0 / jne`
'   ... is the `If Not s` emission (codegen-patterns 10.3)"). The comparison itself is raw
'   pointer identity against the shared Null-object sentinel `&DAT_005c9c80` (confirmed by
'   TBall.ClearAll's identical use of that same address as the compiled form of the `Null`
'   literal for ANY object type), not a `st._stream` field test (that would need a `[ebx+8]`
'   memory operand; the actual byte is `81 FB 80 9C 5C 00`, register-direct). The `Not`
'   inversion also explains the block ORDER: the error/`DoMessage` code sits inline right
'   after the test (the fall-through path, taken when `st` IS null) and the success path
'   (`g_profile.LoadProfile(st)` onward) sits at the `jne` target -- i.e. the source lists
'   the error arm first, under `Then`, exactly as `If Not st Then <error> Else <success>
'   EndIf` reads. `st` is a freshly `New`'d object so in practice this branch is always
'   taken (the success arm always runs); that is what the bytes do and it is reproduced
'   as-is (preserve-by-default).
'   The 8 TScreen.DoProgressBar / <Type>.LoadData(st) pairs, their percentages and callees,
'   are read directly off extracted/callgraph_resolved.tsv's resolved call targets for this
'   VA (0x005659F1), cross-checked against the identical idiom already banked in
'   TProfile.SetUp.bmx (same 0x00C61CD8 = TScreen.DoProgressBar(f,$,$,i), same "Loading" /
'   "00FF00" literals at 0x00C73AA4 / 0x00C6E904, same GetText(1 arg).Replace-free shape --
'   here there is no Replace, DoProgressBar's 2nd arg is the bare GetText() result):
'     10.0  TAchievement.LoadData(st)      0x00C6E8E0 = TAchievement+0x30
'     20.0  TContinent.LoadData(st)        0x00C6098C = TContinent+0x34
'     30.0  TNation.LoadData(st)           0x00C59A10 = TNation+0x48
'     40.0  TClub.LoadData(st)             0x00C59DFC = TClub+0x50
'     60.0  TCompetition.LoadData(st)      0x00C615FC = TCompetition+0x3C
'     80.0  TPromotionPlace.LoadData(st)   0x00C6478C = TPromotionPlace+0x38
'     90.0  TScreen_Stable.LoadData(st)    0x00C6E240 = TScreen_Stable+0x38
'     100.0 TContractOffer.LoadData(st)    0x00C6B7E8 = TContractOffer+0x30
'   (all 8 callee VAs and TProfile+0x34/LoadProfile confirmed directly by
'   extracted/callgraph_resolved.tsv rows keyed on call-site VA 0x005659F1.)
'   After CloseStream(st): g_profile.mynation / g_profile.myclub are re-cached via
'   TNation.SelectById(g_profile.nationid) / TClub.SelectById(g_profile.clubid) -- the
'   retain-new/release-old/store pattern into fields +0x1CC/+0x1D0.
'   g_profile.SetPlayButtonIcon() (slot 0x70, Method, self-only call), then bare calls to
'   TScreen_GameMenu.SetUpScreen() (classtable+0x34, already banked in
'   src/recovered/TScreen_GameMenu.SetUpScreen.bmx), PlayTrack(2)
'   (src/recovered_module/PlayTrack.bmx), TClub.AverageOutStrengthAll() (classtable+0x8C,
'   already banked) -- none of their return values are used.
'   FUN_0058D90B (VA 0x0058D90B, 124 bytes) is called bare with 0 arguments and is NOT a
'   Type slot -- extracted/callgraph_resolved.tsv labels its call here "direct" (exactly
'   like the PlayTrack(2) call two lines above it), i.e. a genuine module-level Function.
'   It is called from NOWHERE else in the whole game (its only entry in
'   extracted/callgraph_resolved.tsv is this call site) and has no decomp/*.c file of its
'   own, so there is no existing name to reuse -- **SyncSteamAchievements is a name coined
'   for this submission**, not an established one. Its own disassembly (read via
'   harness.disasm_original) is: if a Global Int at 0x00C6F3B8 <> 1, return immediately;
'   else `For i = 1 To 100`, and if g_profile.achievements[i-1] > 0 Then build
'   "ACHIEVEMENT_" + i and pass it to SetSteamAchievement (0x004A9D50, already named
'   elsewhere in extracted/callgraph_resolved.tsv) and to one further unnamed helper
'   (0x004A8DA0) with the same value. Its own BODY IS NOT reconstructed by this submission
'   (different VA / a separate, currently unassigned work item) -- it is only referenced by
'   name so this function's own control flow is complete. Flagged under uncertainties.
'   `name.FindLast("#")` / `name.FindLast("@")`: FUN_004A6C20 is _bbStringFindLast
'   (extracted/runtime_helpers.tsv), single explicit argument, exactly as already
'   established in src/recovered/TProfile.GetOriginalName.bmx (the implicit start=0 default
'   compiles to the same trailing `push 0`, not written in source).
'   `saveversion.Contains("#VERSION:1.10")`: FUN_004A6BF0 is _bbStringContains (the
'   corrected identity recorded in TScreen_MainMenu.UpdateLoadTable.bmx's header note --
'   NOT StartsWith). Literal "#VERSION:1.10" read at 0x00C8D958 with harness.read_string.
'   LogLine("LoadGame"): FUN_00505B91 is LogLine (src/recovered_module/LogLine.bmx),
'   literal read at 0x00C8D93C.
'   TProfile.DeleteCorruptKoreanData(): classtable TProfile+0x164, called bare with 0 args
'   (no `add esp` after it pops anything but the call itself needs none) -- already banked
'   in src/recovered/TProfile.DeleteCorruptKoreanData.bmx as a static Function.
'   Error branch: `TScreen.DoMessage(GetText("CMESSAGE_COULDNOTLOADFILE").Replace(
'   "$filename", g_savename), 0, 0)`, return value discarded, Return 0. Literals
'   "CMESSAGE_COULDNOTLOADFILE" at 0x00C7EF30, "$filename" at 0x00C704A4.
'
' SHAPE NOTES (from the raw disassembly, not just the Ghidra decompile)
'   * `st`'s object-truth test at +0x93 is a single flat `If Not st Then / Else / EndIf`, not
'     `If Not (st And st._stream)` (contrast TScreen_MainMenu.UpdateLoadTable, which DOES
'     test `st._stream` too) -- this function's compiled bytes show exactly one `cmp`,
'     `setne`, `movzx`, `cmp eax,0`, `jne`, with no second comparison, so only `st` itself is
'     tested. The block order (error/`DoMessage` inline, success at the jump target) is what
'     pins the polarity to `Not` rather than a bare `If st`; see the header note above for the
'     byte-count evidence (`If st Then` would fuse to a direct 12-byte `cmp`/`je`, not this
'     21-byte materialised-boolean form).
'   * Each `TScreen.DoProgressBar(pct,...)` / `<Type>.LoadData(st)` pair's `add esp,0x10`
'     (4 args) / `add esp,4` (1 arg) confirms the merged-argument reading above: GetText
'     consumes only its own top-of-stack literal, DoProgressBar's cleanup consumes the
'     GetText result plus the two earlier-pushed "00FF00"/0 operands together.
'   * The name hashtag fixup is a genuine short-circuit `And` (`bVar6` is only computed,
'     and only after evaluating the second FindLast, when the first FindLast already
'     failed), matching a plain `If a.FindLast("#") = -1 And a.FindLast("@") = -1 Then ...`
'     with no intermediate Local (the original never stores either FindLast result anywhere
'     other than the immediate comparison).
'!Global g_savename:String
'!Global g_userpath:String
'!Global g_profile:TProfile
LogLine("LoadGame")
g_savename = a0
Local st:TMyStream = New TMyStream
st.SetStream(ReadStream("zipe::" + g_userpath + "Save/" + g_savename + "::newstarsoccerfivesavefile::3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a"))
If Not st Then
	TScreen.DoMessage(GetText("CMESSAGE_COULDNOTLOADFILE").Replace("$filename",g_savename),0,0)
	Return 0
Else
	g_profile.LoadProfile(st)
	TScreen.DoProgressBar(10.0,GetText("Loading"),"00FF00",0)
	TAchievement.LoadData(st)
	TScreen.DoProgressBar(20.0,GetText("Loading"),"00FF00",0)
	TContinent.LoadData(st)
	TScreen.DoProgressBar(30.0,GetText("Loading"),"00FF00",0)
	TNation.LoadData(st)
	TScreen.DoProgressBar(40.0,GetText("Loading"),"00FF00",0)
	TClub.LoadData(st)
	TScreen.DoProgressBar(60.0,GetText("Loading"),"00FF00",0)
	TCompetition.LoadData(st)
	TScreen.DoProgressBar(80.0,GetText("Loading"),"00FF00",0)
	TPromotionPlace.LoadData(st)
	TScreen.DoProgressBar(90.0,GetText("Loading"),"00FF00",0)
	TScreen_Stable.LoadData(st)
	TScreen.DoProgressBar(100.0,GetText("Loading"),"00FF00",0)
	TContractOffer.LoadData(st)
	CloseStream(st)
	g_profile.mynation = TNation.SelectById(g_profile.nationid)
	g_profile.myclub = TClub.SelectById(g_profile.clubid)
	g_profile.SetPlayButtonIcon()
	TScreen_GameMenu.SetUpScreen()
	PlayTrack(2)
	TClub.AverageOutStrengthAll()
	' STEAM STRIPPED: the original calls SyncSteamAchievements() here.
	' Steam is removed from this build by a settled project decision
	' (a deliberate project choice), the same way SteamInit is neutralised. The call is
	' commented rather than deleted so the original control flow stays visible.
	If g_profile.name.FindLast("#") = -1 And g_profile.name.FindLast("@") = -1 Then
		g_profile.name = g_profile.name + "#"
	EndIf
	If g_profile.saveversion.Contains("#VERSION:1.10") Then
		TProfile.DeleteCorruptKoreanData()
	EndIf
	Return 1
EndIf
