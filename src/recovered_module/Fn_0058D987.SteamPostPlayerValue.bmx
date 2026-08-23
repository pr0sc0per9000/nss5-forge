' SteamPostPlayerValue (name OURS -- module-level Function, no reflection record)
' VA 0x0058D987   325 bytes (Ghidra-authoritative)   KIND=Function, no Self.  1 caller.
' sig ()i
' CALLER COUNT CORRECTED. This header said "12 callers" for several passes and it is wrong.
' Scanning every E8 rel32 in every function in Ghidra's inventory finds exactly ONE call
' site: 0x005660D9, inside TProfile.SaveGame (0x00565D99). extracted/callgraph_resolved.tsv
' agrees (one row). Whatever produced 12 counted something else.
' byte-identical vs NSS5.exe (325/325, mode=reloc, reloc_masked=29), verified with
' harness.try_function under NSS5_NO_LEARN=1. Confirmed on three separate process launches
' on worker 320 and once on an independently created tree (320b): identical verdict and the
' same reloc_masked count every time.
' RE-CONFIRMED 2026-08-22 by worker 326, four more fresh process launches across two further
' trees (326 and a freshly created 326b): MATCH 325/325, mode=reloc, reloc_masked=29,
' first_diff=None, identical every run. Its caller was re-measured in the same runs and the
' name this file contributes was shown to be load-bearing there by a control -- see the
' NAME-DROP note in src/recovered_unverified/TProfile.SaveGame.bmx.
'
' ============================ HOW THE LAST 2 BYTES CLOSED ============================
' The body stood at 327 vs 325 for a long time, with the whole residue at ORIGINAL +0x0A9:
'
'   orig   53              push ebx           ; the name cstring (arg3)
'          56              push esi           ; receiver for GetValue -- USED IN PLACE
'          8B 06           mov eax,[esi]
'          FF 90 B8 00 00 00  call [eax+0xB8]
'
'   ours   89 F0           mov eax,esi        ; <-- THE 2 EXTRA BYTES
'          53              push ebx
'          50              push eax
'          8B 00           mov eax,[eax]
'          FF 90 B8 00 00 00  call [eax+0xB8]
'
' Fifteen source spellings of the receiver were measured and none removed that `mov`. That
' was never going to work, and the compiler source says why: type.cpp ClassType::resolve
' builds a non-final virtual method's template as
' `vfn( mem(CG_PTR, tmp("@type"), slot), tmp("@self") )`, so val.cpp Val::find (line 513)
' counts n_self=1 and n_type=1 for EVERY ordinary virtual call, takes its
' `else if( n_self+n_type>1 )` branch, and materialises the receiver into a fresh temp with
' `mov cg,cg_exp`. No receiver spelling avoids that branch.
'
' The mistake was assuming the two extra bytes came from the receiver at all. They did not.
' They came from the two Locals this file used to declare for the C strings:
'
'     Local p:Byte Ptr = "Player Value".ToCString()  /  FindLeaderboard(p)  /  MemFree p
'     Local q:Byte Ptr = g_profile.name.ToCString()  /  ..., q)             /  MemFree q
'
' Val::funArgCast (val.cpp:352, the "convert string to cstring/wstring" block at :381) does
' that conversion BY ITSELF whenever a String argument meets a `Byte Ptr` parameter: it
' emits `bbStringToCString`, stores the result in a compiler temp, and pushes
' `bbMemFree(temp)` onto the call's cleanup list, which is emitted after the call returns.
' That is exactly the original's shape at +0x036..+0x057 and at +0x09C..+0x0C9 -- the
' ToCString, the `mov ebx,eax`, the call, and the trailing `push ebx` / `bbMemFree`. So the
' original wrote `FindLeaderboard("Player Value")` and
' `UploadLeaderboardScore(2, g_profile.GetValue(), g_profile.name)`, with no Locals and no
' MemFree of its own. All five of those hand-written lines were duplicating work the
' compiler already does.
'
' Why that moved the receiver copy. Writing the conversion out by hand put it in its own
' earlier STATEMENT, so by the time the UploadLeaderboardScore statement was reached the
' cstring already sat in ebx and Val::find's `mov cg,...` was flushed late, immediately
' before the argument pushes. A late `cg` is not live across any call, so it takes eax and
' `mov eax,esi` survives as a real two-byte copy. Letting funArgCast do it folds the
' conversion INTO the call statement, and the hoisted statements of the arguments come out
' left to right: arg2's `mov cg,[g_profile]` first, then arg3's `bbStringToCString` call.
' `cg` is therefore live across that call, must be callee-saved, lands in esi, and the copy
' folds into the load itself -- `8B 35` at +0x091, `push esi` in place at +0x0AA.
'
' The same shift is what produces `sub esp,4`. With `cg` pinned in esi across the whole
' argument sequence there are four values competing for three callee-saved registers (cg,
' the cstring temp, the status String and `t`), `t` loses on the section 22 cost formula
' because it is live across the whole loop, and it spills to [ebp-4]. The old no-Local
' spellings all measured 317 because they got a short-lived `cg` in eax: 5 bytes for `A1`
' instead of 6 for `8B 35`, no `sub esp,4`, and four [ebp-4] accesses each one byte
' shorter. 1+3+4 = the missing 8, now accounted for exactly.
'
' NOTHING IN THE ALLOCATOR NEEDED TO CHANGE. The earlier reading of this body -- that the
' outcome hung on cgallocregs.cpp's coalescing pass and was unreachable from source -- was
' wrong. Coalescing behaves identically in both builds. What changed is the live range the
' allocator was handed, and that is decided by statement structure in the source.
'
' GENERAL RULE FOR THE NEXT BODY: if a reconstruction hand-writes `.ToCString()` into a
' Local to feed a `Byte Ptr` Extern parameter and then hand-writes the matching `MemFree`,
' suspect it. funArgCast does String -> `Byte Ptr` (and String -> `Short Ptr`, via
' bbStringToWString) automatically, with the free in the call's cleanup, and the hand
' spelling is NOT byte-equivalent: it moves the conversion into its own statement and
' changes which values are live across which calls.
'
' ============================ NOT A DIVERGENCE ============================
' Steam integration functions get checked for a possible divergence, the way
' src/recovered_module/SteamInit.bmx diverges from the original OpenSteam call. This one
' does not qualify. Every Steam call below sits behind a single guard,
' `If g_profile_int43 <> 1 Then Return 0`, on the same flag SteamInit.bmx writes as
' g_steamstate at 0x00C6F3B8 (confirmed: both functions read/write DAT_00c6f3b8 in Ghidra's
' decompilation). SteamInit fixes that flag at 0 (offline) unconditionally, so the guard here
' is never satisfied and FindLeaderboard / ReadSteam / UploadLeaderboardScore never run.
' Unlike OpenSteam, nothing in this function calls End or otherwise halts the process on a
' Steam failure -- the worst case, even if the guard were somehow satisfied, is a bounded
' 2-second poll loop that falls through and returns 0. Reproducing the original logic
' verbatim is therefore safe: it changes no observable behaviour versus a stub, needs no
' neutralisation, and keeps the body faithful to NSS5.exe instead of inventing a divergence
' nothing requires. The build already proves the link surface itself is harmless: the probe
' compiles and links clean against extern/steamstub/libsteamstub.a (dlltool-built from the
' shipped binary/steamstub.dll, the game's own file, not a Valve component) with no
' BUILD_FAIL. Fn_0058D90B.SyncSteamAchievements.bmx, the sibling Steam Function called from
' TProfile.LoadSavedGame, reaches the identical conclusion for the identical reason.
'
' ============================ WHAT IT ACTUALLY IS ============================
' It posts the player's value to a Steam leaderboard. It is NOT what the caller's notes
' predicted. TProfile.SaveGame.bmx's header recorded a working hypothesis that this was a
' save/backup DIRECTORY SCAN -- LoadDir/ReadDir, a file-age check, a log line. Every part
' of that was wrong, and reading the six string literals FIRST (as that header itself
' advised) disproved it in one step:
'
'   0xC94710  'Steamstate offline!'
'   0xC94744  'Finding leaderboard'
'   0xC94778  'Player Value'          <- the leaderboard NAME
'   0xC9479C  'leaderboard:found'     <- an async status token, not a filename
'   0xC947CC  'upload'                <- another status token
'   0xC947E4  'Post end: '
'
' The "directory API" calls were PE import thunks into STEAMSTUB.DLL, and the "MilliSecs
' file-age check" is a 2-second timeout on an asynchronous Steam callback:
'
'   0x004A9D30  FindLeaderboard          STEAMSTUB.DLL
'   0x004A9D48  ReadSteam                STEAMSTUB.DLL
'   0x004A9D58  UploadLeaderboardScore   STEAMSTUB.DLL
'
' Named by parsing the PE import directory -- a lookup, not an inference. That work is now
' generalised: scripts/extract_imports.py names all 324 import thunks across 11 DLLs into
' extracted/dll_imports.tsv, and helper_map.brl_table() reads it, so no future body has to
' rediscover this. The four BlitzMax runtime helpers it also uses were added to
' extracted/brl_functions_inferred.tsv with evidence: 0x004A4860 _bbMilliSecs (a bare `jmp`
' to the WINMM timeGetTime thunk -- blitz_app.c:115 is a one-line tail call), 0x004A6E20
' _bbStringToCString, 0x004A7960 _bbStringFromCString, 0x004A8DA0 _bbMemFree. Two of those
' four, bbStringToCString and bbMemFree, are now known to be emitted by funArgCast rather
' than written by hand -- see the section above.
'
' Shape: if the Steam-initialised Global is not 1, print and bail. Otherwise ask for the
' 'Player Value' leaderboard, then poll ReadSteam() in a loop, printing each non-empty
' status line; when the status is exactly 'leaderboard:found', upload (mode 2, the
' profile's GetValue(), the profile's name). Leave the loop after 2 seconds, on a MilliSecs
' wraparound, or once a status containing 'upload' arrives. Print the elapsed time.
'
' ============================ WHERE THIS FILE LIVES ============================
' It lives in src/recovered_module/ and is named in harness.MODULE_SKIP. Both halves of
' that are load-bearing and they pull in opposite directions:
'   * IN src/recovered_module/ because helper_map.orig_functions() builds the ORIGINAL-side
'     call-target name table by scanning that directory and nothing else. Its only caller,
'     TProfile.SaveGame, has a `call 0x0058D987` that cannot mask without a name for this
'     VA -- and compiling the real body into the caller's probe does NOT substitute for the
'     name, because compare()'s byte-level `_same_callee` fallback recurses without the
'     helper tables and so cannot prove any callee that itself calls C-runtime helpers
'     (measured: 850/850 mode=diff, one differing operand). orig_functions() strips the
'     "Fn_<8hex>." filename prefix, so this file contributes the name "SteamPostPlayerValue",
'     which is what the declared Function compiles to on our side as well.
'   * IN harness.MODULE_SKIP because every OTHER file in src/recovered_module/ is emitted
'     into EVERY probe, pragmas included. Without the skip, this file's '!Import and '!Raw
'     Extern block would reach bodies that have nothing to do with Steam, and the
'     STEAMSTUB.DLL import would land in src/assembled/ where the DLL does not exist -- the
'     loader kills the process before any code runs (STATUS_DLL_NOT_FOUND). MODULE_SKIP is
'     also what keeps the import out of the whole-program build, since assemble.py takes its
'     module Functions from harness.module_functions(). This is the identical arrangement
'     already used for the byte-verified sibling Fn_0058D90B.SyncSteamAchievements.bmx.
' scripts/progress.py VERIFIED_NOT_SHIPPED names
' "src/recovered_module/Fn_0058D987.SteamPostPlayerValue.bmx" as OMITTED with "harness.py
' MODULE_SKIP" as the mechanism, and check_not_shipped() cross-checks that claim against
' MODULE_SKIP itself. The body IS counted in the totals; being unshipped is a fact about the
' build, not about whether it matches.
' NOTE FOR ANY FUTURE MOVE: change MODULE_SKIP first, THEN move the file. In the other order
' there is a window in which every probe in the project picks up this Extern block.
'
' ============================ BUILD NOTE (harness collision) ============================
' The '!Raw End Extern line below carries a trailing comment to keep its TEXT unique, and it
' must keep one. harness.merge_globals() deduplicates '!Raw pragma payloads by bare
' lowercased text with no awareness of which Extern block a line closes. This body's
' End Extern is emitted before src/recovered_module/Fn_0058D81A.GetClipboardText.bmx's own
' End Extern (that file declares an unrelated '!Raw Extern "Win32" clipboard block), so
' without the comment this body wins the dedup slot, the clipboard block is left open, every
' module Global declared afterwards lands inside it, and the probe dies with
'     Syntax error in extern block - expecting Const, Global, Function or Type declaration
' Reproduced under NSS5_NO_LEARN=1 and confirmed by reading the generated probe, where the
' Win32 block's End Extern was simply absent. The trailing comment is confined to this file.
' The alternative fixes -- adding GetClipboardText to harness.MODULE_SKIP, or making
' merge_globals dedup per Extern block -- both edit a shared tool and were not made here.
' src/recovered_unverified/TProfile.CheckAchievement.bmx carries its own '!Raw Extern block
' and hits the identical BUILD_FAIL; the same one-line fix applies to it.
'
' ============================ DOWNSTREAM ============================
' TProfile.SaveGame (0x00565D99) omits exactly one 5-byte CALL to this function and is
' otherwise 845/850. With this callee byte-identical, rule 13.3's objection -- do not stub an
' unverified callee to make a caller mask -- no longer applies to it.
'
'!Import "<repo>/extern/steamstub/libsteamstub.a"
'!Raw Extern
'!Raw Function FindLeaderboard(name:Byte Ptr)
'!Raw Function ReadSteam:Byte Ptr()
'!Raw Function UploadLeaderboardScore(mode:Int, value:Int, name:Byte Ptr)
'!Raw End Extern ' text kept unique on purpose -- see BUILD NOTE above
'!Global g_profile_int43:Int
'!Global g_profile:TProfile
	If g_profile_int43 <> 1 Then
		Print "Steamstate offline!"
		Return 0
	EndIf
	Print "Finding leaderboard"
	FindLeaderboard("Player Value")
	Local t:Int = MilliSecs()
	Local s:String
	Repeat
		s = String.FromCString(ReadSteam())
		If s.length > 0 Then Print s
		If s = "leaderboard:found" Then
			UploadLeaderboardScore(2, g_profile.GetValue(), g_profile.name)
		EndIf
	Until MilliSecs() > t + 2000 Or MilliSecs() < t Or s.Contains("upload")
	Print "Post end: " + (MilliSecs() - t)
	Return 0
