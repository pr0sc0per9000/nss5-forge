' TProfile.SaveGame
' VA 0x00565D99   850 bytes   KIND=Method   SIG=($)i   slot 0x40
' byte-identical vs NSS5.exe (850/850, mode=reloc, reloc_masked=95), verified with
' harness.try_method under NSS5_NO_LEARN=1 on worker 320 and again on an independently
' created tree (320b). Closed 2026-08-22, worker 320.
'
' INDEPENDENTLY RE-MEASURED 2026-08-22 by worker 326, four fresh process launches across two
' trees (326, and 326b created from scratch for this check): MATCH 850/850, mode=reloc,
' reloc_masked=95, first_diff=None, every run identical. The callee was re-measured in the
' same runs: MATCH 325/325, mode=reloc, reloc_masked=29, identical every run.
'
' TWO CONTROLS WERE RUN, because "it matches now" does not by itself show that the 5-byte
' call was the whole defect or that the mask is honest.
'   ABLATION. Delete the single line `SteamPostPlayerValue()` from this body, change nothing
'   else, and the oracle returns exactly the state this file sat in for several passes:
'   MISMATCH, mode=len, our_len 845 vs orig_len 850, delta -5. One line separates -5 from
'   MATCH, so the call was the only gap. (Read that row's `matched=542`/`first_diff=31` as a
'   diagnostic, not as agreement: on a length disagreement harness re-derives first_diff
'   through masked_first_diff with EMPTY ournames/ourfns, so our own call operands cannot
'   mask and the first unmaskable one lands early. The verdict is decided by the length test
'   before any masking, which is why -5 can never be masked into a MATCH.)
'   NAME-DROP. compare() route (a0) masks a call by looking VA 0x0058D987 up in
'   helper_map.orig_functions(). Remove that one row IN MEMORY ONLY and re-run: MISMATCH,
'   mode=diff, reloc_masked 95 -> 94, first_diff=+0x341, and the disassembly window shows the
'   two sides byte-identical on both sides of a single differing rel32:
'       orig  005660D9  E8 A9 78 02 00   call 0x58d987
'       ours  0051FB7A  E8 6A 86 00 00   call 0x5281e9
'   So our body really does emit the call, at the right offset, and the MATCH turns on
'   exactly one name -- the one contributed by the byte-identical
'   src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx. That is what discharges rule
'   13.3 here: the name is earned by a verified body, and if it were not there the caller
'   would fail rather than quietly pass.
'
' NO OTHER DEFECT IS HIDING BEHIND THE CALL. Beyond the byte verdict, the one class of error
' a masked-relocation MATCH cannot catch was checked by hand (CONTRIBUTING, "A byte match
' does not prove your Globals are right"): the two module Globals this body reads are
' g_profile_int26 and g_screen_mainmenu_int26, and extracted/globals_final.tsv maps those
' names to 0x00C68BC8 and 0x00C6E9A8, the same addresses this header records. Disassembling
' the original 850 bytes shows 19 references to 0xC68BC8 and 6 to 0xC6E9A8, matching the use
' counts here. g_screen_mainmenu_int26:String also agrees with the already-verified
' src/recovered/TReplay.LoadReplayFile.bmx, so assemble.py cannot merge two conflicting types
' for it. (globals_final.tsv still calls both Int; that disagreement is the documented
' correction above, not a naming conflict.)
'
' WHAT CLOSED IT. This body sat at 845/850 for several passes, short by exactly one 5-byte
' `call 0x0058D987`, deliberately omitted because codegen-patterns 13.3 forbids stubbing an
' unverified callee to make a caller mask. The callee, SteamPostPlayerValue, is now
' byte-identical (325/325) and lives at
' src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx, so 13.3's objection is gone:
' the name the mask relies on is earned by a verified body, not invented by a placeholder.
' The call is restored below and the length is now exact.
'
' TWO THINGS HAD TO BE TRUE, and only one of them was obvious.
'   1. The callee had to be byte-verified. It is -- see its own header for how its last
'      2 bytes closed (Val::funArgCast does String -> `Byte Ptr` conversion, and its
'      matching MemFree, by itself; hand-writing them changes which values are live across
'      which calls).
'   2. The callee's FILE had to live in src/recovered_module/, because
'      helper_map.orig_functions() builds the ORIGINAL-side name table by scanning that
'      directory and nothing else. Without a name for VA 0x0058D987 the `E8` here cannot
'      mask. MEASURED, and this is the part worth recording: compiling the REAL 325-byte
'      body straight into this probe (via '!Raw) is NOT enough. It gives 850/850 mode=diff
'      with exactly one differing operand, reloc_masked 94. compare()'s byte-level
'      `_same_callee` fallback recurses WITHOUT ournames/origtab/ourfns, so inside the
'      callee its own calls to bbStringToCString / bbMemFree / bbStringFromCString cannot
'      mask, the callee compares "diff", and the fallback correctly refuses to bless the
'      call. `_same_callee` can only prove a callee that makes no C-runtime calls. Route
'      (a0), by name, is the only one available here.
' Once the file moved (and was added to harness.MODULE_SKIP so its STEAMSTUB.DLL Extern
' stays out of every probe and out of src/assembled/), the local '!Raw placeholder below
' is all this probe needs to link, and the operand masks by name: 850/850, reloc_masked 95.
' This is the same shape src/recovered/TProfile.LoadSavedGame.bmx already uses for its own
' Steam callee at 0x0058D90B.
'
' WHY THIS FILE STAYS IN src/recovered_unverified/ although it is byte-identical: the
' location is a build-surface decision and the byte verdict above is what matters;
' progress.py counts it from the phrase above regardless of tree.
'
' CORRECTION 2026-08-23. This paragraph used to say the file "must stay named" in
' assemble.py's UNVERIFIED_SKIP because assembling it "would leave an undefined reference"
' to SteamPostPlayerValue. That was wrong, and it cost the shipped build its entire save
' feature: with the name in UNVERIFIED_SKIP, TProfile.SaveGame assembled to an EMPTY
' `Method SaveGame:Int(a0:String) / End Method`, so every one of its six callers -- the
' StartCareer first-save, the pre-travel autosave in TScreen_WorldMap.SetUpScreen, the
' post-fixture save in TProfile.FixturePlayed, TScreen_GameMenu.ButtonQuit,
' TScreen_Options.ButtonTick and TScreen_SeasonReview.ButtonPlay -- wrote nothing at all,
' and the main menu's load list, which scans g_userpath + "Save/" for *.sav, was
' permanently empty.
' There is no undefined reference. The '!Raw pragma pair below declares an empty
' `Function SteamPostPlayerValue:Int()`, and assemble.py emits '!Raw fragments verbatim
' into the assembled program -- the same mechanism that has been carrying
' src/recovered/TProfile.LoadSavedGame.bmx's identical SyncSteamAchievements placeholder
' in every build. The file declares no '!Import, so nothing re-imports the Steam link
' surface, and the empty placeholder also removes the up-to-2s dead leaderboard poll the
' real callee would otherwise add to every save. The entry has been removed from
' UNVERIFIED_SKIP; see the note left in its place there.
'
' THE CALL THAT USED TO BE MISSING:
'     E8 A9 78 02 00   call 0x0058D987
' 5 bytes, 0 args, return value discarded, immediately before the trailing `mov eax,0`. It
' is a MODULE-LEVEL Function of 325 bytes, now recovered and byte-identical at
' src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx. It posts the player's value to
' a Steam leaderboard: FindLeaderboard("Player Value"), then a 2-second poll of ReadSteam()
' and an UploadLeaderboardScore when the status reads "leaderboard:found". Read that file
' for the analysis. It is guarded by the same offline flag SteamInit.bmx pins at 0, so the
' Steam calls never run.
'
' (An earlier pass here recorded a working hypothesis that 0x0058D987 was a save/backup
' DIRECTORY SCAN -- LoadDir/ReadDir, a file-age check, a log line. Every part of it was
' wrong; the "directory API" calls are PE import thunks into STEAMSTUB.DLL and the
' "file-age check" is the 2000 ms callback timeout. Reading the string literals first, as
' that same note advised, settled it in one step. The hypothesis is dropped rather than
' preserved because it sent at least one later pass down the wrong path.)
'
' Tooling that came out of it and is now available to every body:
'   * extracted/dll_imports.tsv -- all 324 import thunks across 11 DLLs, named from the PE
'     import directory (scripts/extract_imports.py); helper_map.brl_table() reads it.
'   * harness '!Import pragma -- bcc rejects `Import` anywhere but the top of the file, so
'     '!Raw could not carry one. Needed by any body that calls into a DLL.
'   * extern/steamstub/libsteamstub.a -- a real import library built with dlltool from the
'     shipped steamstub.dll, not a stub.
'
' RESOLVED AND TRUSTED (do not re-derive):
'   Self is `ebx` ([ebp+8]), a0 (the requested save name, "" = keep current) is `esi`
'   ([ebp+0xc]).
'   `MODULE_TYPES["TBank"] = "BRL.Bank"` was ADDED to scripts/harness.py (was missing;
'     without it, `Local bank:TBank = CreateBank(0)` fails to build with the exact
'     "Unable to convert from 'TBank' to 'TBank'" shadowing symptom documented for
'     TSound/TImage/TGraphicsMode -- TBank's slot layout (New/Delete/_pad/Buf/Lock/Unlock/
'     Size/Capacity/Resize/Read/Write/PeekByte..PokeDouble/Save/Load/Create/CreateStatic)
'     matches tools/blitzmax-legacy-src/mod/brl.mod/bank.mod/bank.bmx exactly).
'   `g_profile_int26` (0x00C68BC8) and `g_screen_mainmenu_int26` (0x00C6E9A8) are BOTH
'     String, not Int as globals_final.tsv claims ("dword int access") -- full
'     retain/release traffic around every store to g_profile_int26 (guide 11.2/16.7), and
'     both are pushed directly into `_bbStringConcat`/`_bbStringReplace`/`_bbStringCompare`
'     with no Int->String conversion anywhere. g_screen_mainmenu_int26 as String is already
'     an established precedent -- src/recovered/TReplay.LoadReplayFile.bmx uses the same
'     Global the same way. g_profile_int26 is the profile's OWN save filename (e.g.
'     "foo.sav"); g_screen_mainmenu_int26 is the save-data directory ("Save/" is appended
'     to it at every use site here, matching TReplay's "Replays/" pattern).
'   Branch swap (guide 21, solo relational If/Else): the source is `If a0 <> "" Then
'     [copy-and-rename branch] Else [in-place-backup branch]`, the NEGATION of the more
'     natural `If a0 = "" Then ... Else ...` reading. Confirmed by bytes: original's
'     fall-through (immediately after the StringCompare) is the a0-branch, and the
'     StringCompare-equal case is the JUMP target further down -- the mirror image of what
'     a naive `If a0 = ""` would compile to. localise_diff isolated this as two large gaps
'     (a 99-byte delete + a 98-byte replace) that both vanished together once negated.
'   CreateBank(0) is BRL.Bank's free Function (`Function CreateBank:TBank(size=0)`),
'     explicit `0` argument matches the disassembly's `push 0` exactly.
'   TMyBankStream.Create(bank) -- already-recovered static Function
'     (src/recovered/TMyBankStream.Create.bmx).
'   Self.SaveProfile(stream) -- same-Type sibling call (TProfile slot 0x38).
'   Cross-Type static Function calls, all resolved via vtable_map.tsv/class_tables.tsv:
'     TAchievement.WriteData(:TStream)i slot 0x34, TContinent.WriteData(:TStream)i 0x38,
'     TNation.WriteData(:TStream)i 0x4c, TClub.WriteData(:TStream)i 0x54,
'     TCompetition.WriteData(:TStream,i)i 0x40 (called with a literal 0 second arg),
'     TPromotionPlace.WriteData(:TStream)i 0x3c, TScreen_Stable.WriteData(:TStream)i 0x3c,
'     TContractOffer.WriteData(:TStream)i 0x34. All take the ONE stream argument only --
'     Ghidra's printed call merges the FOLLOWING call's pushes into these (guide "GHIDRA'S
'     PRINTED ARGUMENT LIST IS NOT EVIDENCE"), confirmed against each call's own
'     `add esp,N`.
'   GetText(a0)="Saving" is the ALREADY-RECOVERED 1-arg module Function
'     (src/recovered_module/GetText.bmx) -- Ghidra's printed 3-arg
'     `GetText("Saving","FF0000",0)` is the SAME merged-call artifact: the "FF0000" and `0`
'     belong to the FOLLOWING TScreen.DoProgressBar(f,$,$,i)i call, confirmed by each
'     call's own `add esp,N` (4 bytes for GetText, 0x10 for DoProgressBar).
'   The 7 DoProgressBar float literals, read directly from the exe: 10.0, 20.0, 30.0, 60.0,
'     80.0, 90.0, 100.0 (one after each WriteData call except the very first,
'     TAchievement.WriteData, which has none before it).
'   `New ZipWriter` at the classtable-literal-only site (`bbObjectNew(&ZipWriter's
'     classtable)`, no explicit call to ZipWriter.New at 0x0058DDC3) -- ZipWriter is a
'     THIRD-PARTY Type (src/recovered_thirdparty/zipengine/), reconstructed there
'     separately; this file only calls its already-recovered slots (OpenZip 0x4c,
'     AddStream 0x5c, CloseZip 0x60).
'   `CopyFile(src$,dst$)` -- BRL.FileSystem free Function, confirmed argument order from
'     tools/blitzmax-legacy-src/mod/brl.mod/filesystem.mod/filesystem.bmx.
'   `CloseStream(stream)` -- the BRL.Stream free-Function form (NOT `stream.Close()`
'     virtual dispatch), matches the DIRECT E8 call to the alias-set address 0x5B812B
'     (`__brl_stream_TIO_Delete|_brl_filesystem_CloseFile|_brl_stream_CloseStream|...`),
'     confirmed against `tools/blitzmax-legacy-src/mod/brl.mod/stream.mod/stream.bmx:821`.
'   `GCCollect()` -- brl.blitz's extern alias `Function GCCollect()="bbGCCollect"`
'     (guide 15.2), matches the zero-arg direct call at 0x4A8980.
'   `GCMemAlloced()` -- brl.blitz's extern alias `Function GCMemAlloced()="bbGCMemAlloced"`
'     (blitz.bmx:353), matches the zero-arg direct call at 0x4A8550
'     (`mov eax,[0xcf4388] ; ret`, confirmed against
'     tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_gc_rc.c:330's
'     `bbGCMemAlloced()`). This E8 cannot mask against our own GCC-compiled C runtime
'     (guide 15.4 -- the technique only works for bcc output), so it shows as an
'     unmaskable operand-only difference; harmless, does not affect the length.
'
' Oracle: MATCH, orig_len=850 our_len=850, mode=reloc, reloc_masked=95, NSS5_NO_LEARN=1.
' Re-run clean on two independent trees. The `'!Raw Function SteamPostPlayerValue:Int() /
' '!Raw End Function` placeholder below exists ONLY so this probe links -- the real body is
' src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx and is what names the original
' side of the call operand. Do not treat the placeholder as a recovered body.

'!Global g_profile_int26:String
'!Global g_screen_mainmenu_int26:String
'!Raw Function SteamPostPlayerValue:Int()
'!Raw End Function
LogLine("SaveGame")
LogLine("GCMemAlloced=" + String(GCMemAlloced()))
If a0 <> ""
	CopyFile(g_screen_mainmenu_int26 + "Save/" + g_profile_int26, g_screen_mainmenu_int26 + "Save/" + a0 + ".bak")
	g_profile_int26 = a0 + ".sav"
Else
	CopyFile(g_screen_mainmenu_int26 + "Save/" + g_profile_int26, g_screen_mainmenu_int26 + "Save/" + g_profile_int26.Replace(".sav", ".bak"))
EndIf
Local bank:TBank = CreateBank(0)
LogLine("Bank capacity=" + String(bank.Capacity()))
Local stream:TMyBankStream = TMyBankStream.Create(bank)
Self.SaveProfile(stream)
TAchievement.WriteData(stream)
TScreen.DoProgressBar(10.0, GetText("Saving"), "FF0000", 0)
TContinent.WriteData(stream)
TScreen.DoProgressBar(20.0, GetText("Saving"), "FF0000", 0)
TNation.WriteData(stream)
TScreen.DoProgressBar(30.0, GetText("Saving"), "FF0000", 0)
TClub.WriteData(stream)
TScreen.DoProgressBar(60.0, GetText("Saving"), "FF0000", 0)
TCompetition.WriteData(stream, 0)
TScreen.DoProgressBar(80.0, GetText("Saving"), "FF0000", 0)
TPromotionPlace.WriteData(stream)
TScreen.DoProgressBar(90.0, GetText("Saving"), "FF0000", 0)
TScreen_Stable.WriteData(stream)
TScreen.DoProgressBar(100.0, GetText("Saving"), "FF0000", 0)
TContractOffer.WriteData(stream)
Local zw:ZipWriter = New ZipWriter
If zw.OpenZip(g_screen_mainmenu_int26 + "Save/" + g_profile_int26, 0)
	zw.AddStream(stream, "newstarsoccerfivesavefile", "3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a")
EndIf
CloseStream(stream)
zw.CloseZip("")
GCCollect()
SteamPostPlayerValue()
