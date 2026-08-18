' TProfile.SaveGame -- NOT VERIFIED. DO NOT move to
' src/recovered/ until FUN_0058D987 (see below) is independently recovered/named.
' VA 0x00565D99   850 bytes   KIND=Method   SIG=($)i   slot 0x40
'
' STATUS: ours = 845 bytes (delta -5). localise_diff.py: 1 length-changing gap, -5 of -5
' -> COMPLETE, and it is the LAST thing in the function. Every other byte in the body --
' all 8 WriteData calls, all 7 DoProgressBar calls, the branch structure, the zip-write
' block, the refcount-assignment to g_profile_int26 -- is confirmed correct (reloc_masked
' climbs to 71 successfully-named operands; first_diff sits at ORIGINAL offset +832, i.e.
' the very last statement).
'
' THE ONLY GAP: the final call
'     E8 A9 78 02 00   call 0x0058D987
' (5 bytes, 0 args, return value discarded, right before the trailing `mov eax,0`) is a
' MODULE-LEVEL Function -- 325 bytes, 12 callers across the game (per
' extracted/ghidra/function_inventory.tsv), UNNAMED, and NOT YET RECOVERED anywhere in
' src/recovered_module/. Per codegen-patterns.md guide 13.3, a caller must never be made to
' mask by stubbing an unverified callee -- so this line is deliberately OMITTED here rather
' than faked, and the resulting 5-byte deficit is exactly and only that omission (confirmed
' by localise_diff: zero other gaps, zero subs).
'
' WHAT FUN_0058D987 LOOKS LIKE, for whoever picks it up (VA 0x0058D987, 325 bytes):
'   * Guarded by `cmp dword ptr [0xc6f3b8],1 / je +continue` -- a Global "Steam
'     initialised?" flag. If not 1, it just Prints 'Steamstate offline!' (string at
'     0xc94710, confirmed via harness.read_string) and returns.
'   * If the flag IS 1, it Prints a second string (0xc94744) and enters what looks like a
'     directory-scan loop: LoadDir-style setup (`call 0x4a9d30`, `call 0x4a8da0` --
'     probably CurrentDir/ChangeDir), a MilliSecs()-shaped call (`call 0x4a4860`, called
'     FOUR times and compared with `+0x7D0` = 2000, i.e. a millisecond timeout/age check),
'     `call 0x4a9d48` / `call 0x4a7960` (likely ReadDir/NextFile -- returns a filename
'     string used at [edi+8] as an Int test, i.e. probably a directory-entry struct with a
'     length or attribute field), `_bbStringCompare` against the string at 0xc9479c, and
'     `_bbStringContains` (0x4A6BF0 -- CONFIRMED this exact address per codegen-patterns.md
'     15.5's worked correction, do not use `.StartsWith` here) against the string at
'     0xc947cc. The tail builds a log message via `_bbStringFromInt` + concat with the
'     literal at 0xc947e4 and Prints it (0x59cc21 = _brl_standardio_Print, per
'     brl_functions.tsv), then loops back (`je 0x58d9e6`) for the next directory entry.
'   * Reads overall like "scan the save folder, and if a backup/temp file is older than a
'     threshold, log it" -- consistent with being called at the very end of SaveGame, after
'     the zip is closed. Read the six literal strings at 0xc94744/0xc94778/0xc9479c/
'     0xc947cc/0xc947e4 with harness.read_string() before starting; they were not pulled
'     during this pass (time budget) but will very likely name the loop precisely (likely a
'     directory path, a file extension/suffix, and a log-message template).
'   * NOT attempted further here: this is a real sub-investigation (directory APIs +
'     MilliSecs semantics + an unfamiliar list Global at 0xc6f028), not a quick lookup.
'
' ######################## CORRECTION -- THE ABOVE IS WRONG ########################
' Everything in the two bullets above about a DIRECTORY SCAN is disproven. Reading the six
' string literals first -- exactly as those bullets advised -- settled it in one step:
'
'     0xC94744 'Finding leaderboard'   0xC94778 'Player Value'
'     0xC9479C 'leaderboard:found'     0xC947CC 'upload'      0xC947E4 'Post end: '
'
' FUN_0058D987 posts the player's value to a STEAM LEADERBOARD. The supposed LoadDir/ReadDir
' calls are PE import thunks into STEAMSTUB.DLL -- 0x004A9D30 FindLeaderboard, 0x004A9D48
' ReadSteam, 0x004A9D58 UploadLeaderboardScore -- and the "file-age check" is a 2000 ms
' timeout on an asynchronous Steam callback, polled in a loop. 0xC6F028 is not "an
' unfamiliar list Global": globals_final.tsv already types it TProfile (verified/high), and
' the loop uses its `name` field (+0x14) and its GetValue() method (slot 0xB8).
'
' It is recovered to +2 bytes of 325 and preserved at
' src/recovered_unverified/Fn_0058D987.SteamPostPlayerValue.bmx, which carries the full
' analysis and the ten source spellings that were measured. The residual defect is a
' 2-byte receiver materialisation (`mov eax,esi`) that bcc emits for a Local receiver and
' the original does not -- the section 18.2 register-identity class, not a comprehension
' gap.
'
' SO SaveGame STILL CANNOT BE PROMOTED. Rule 13.3 forbids stubbing an unverified callee to
' make a caller mask, and the callee remains unverified. The 5-byte gap here is confirmed
' to be exactly and only that call.
'
' Tooling that came out of it and is now available to every body:
'   * extracted/dll_imports.tsv -- all 324 import thunks across 11 DLLs, named from the PE
'     import directory (scripts/extract_imports.py); helper_map.brl_table() reads it.
'   * harness '!Import pragma -- bcc rejects `Import` anywhere but the top of the file, so
'     '!Raw could not carry one. Needed by any body that calls into a DLL.
'   * extern/steamstub/libsteamstub.a -- a real import library built with dlltool from the
'     shipped steamstub.dll, not a stub.
' ##################################################################################
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
' Oracle: MISMATCH mode=len, orig_len=850 our_len=845 (delta -5), NSS5_NO_LEARN=1,
'. localise_diff.py delta_accounted -5 of -5 (COMPLETE), single gap, the
'   missing FUN_0058D987() call.

'!Global g_profile_int26:String
'!Global g_screen_mainmenu_int26:String
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
' FUN_0058D987() -- see header. Omitted: not recovered, must not be stubbed (guide 13.3).
