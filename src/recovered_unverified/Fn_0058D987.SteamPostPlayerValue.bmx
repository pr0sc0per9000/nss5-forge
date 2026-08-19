' SteamPostPlayerValue (name OURS -- module-level Function, no reflection record)
' VA 0x0058D987   325 bytes (Ghidra-authoritative)   KIND=Function, no Self.  12 callers.
' NOT VERIFIED -- NEAR MISS: ours 327 bytes (delta +2). One single defect remains, fully
' characterised below. Verified via harness.try_function under NSS5_NO_LEARN=1.
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
' _bbStringToCString, 0x004A7960 _bbStringFromCString, 0x004A8DA0 _bbMemFree.
'
' Shape: if the Steam-initialised Global is not 1, print and bail. Otherwise ask for the
' 'Player Value' leaderboard, then poll ReadSteam() in a loop, printing each non-empty
' status line; when the status is exactly 'leaderboard:found', upload (mode 2, the
' profile's GetValue(), the profile's name). Leave the loop after 2 seconds, on a MilliSecs
' wraparound, or once a status containing 'upload' arrives. Print the elapsed time.
'
' ============================ THE REMAINING 2 BYTES ============================
' Everything else matches: prologue INCLUDING `sub esp,4`, the register assignment
' (ebx=cstring, esi=profile, edi=status string, [ebp-4]=t), every call target, every
' literal, the whole loop and its three-term Until.
'
' The entire residue is ONE materialisation, at ORIGINAL +0x0A9 (0x0058DA30):
'
'   orig   53              push ebx           ; the name cstring (arg3)
'          56              push esi           ; Self for GetValue -- USED IN PLACE
'          8B 06           mov eax,[esi]
'          FF 90 B8 00 00 00  call [eax+0xB8]
'
'   ours   89 F0           mov eax,esi        ; <-- THE 2 EXTRA BYTES
'          53              push ebx
'          50              push eax
'          8B 00           mov eax,[eax]
'          FF 90 B8 00 00 00  call [eax+0xB8]
'
' bcc materialises a Local receiver into eax before pushing it; the original pushes the
' register directly. This is the section 18.2 / 22 physical-register-identity class, not a
' comprehension gap.
'
' TEN source spellings were measured (all under NSS5_NO_LEARN=1). The copy is present in
' every one that produces the correct frame; only its register changes:
'
'   receiver read directly from the Global, no Local     317  (-8)  no copy, but no early
'                                                                   load, so t never spills
'                                                                   and `sub esp,4` is absent
'   Local g, .name re-read from the Global               327  (+2)  copy in eax<-esi   <== THIS FILE
'   Local g, .name read through g                        322  (-3)  copy, and 5 bytes lost
'                                                                   on the second Global load
'   Local g declared at function top                     327  (+2)  copy
'   g assigned separately from its declaration           327  (+2)  copy
'   GetValue result into its own Local first             327  (+2)  copy
'   cstring Local reused (p) instead of a fresh q        327  (+2)  copy, roles swap to
'                                                                   ebx=profile/esi=cstring
'   both Locals hoisted above the loop                   327  (+2)  copy
'   g set to Null after use (raise usage)                327  (+2)  copy
'   MemFree written with parentheses                     327  (+2)  copy
'
' WHY THE EARLY LOAD IS REQUIRED AT ALL, and why it cannot simply be dropped: the original
' spills `t` to [ebp-4], which is what produces `sub esp,4`. It only spills because FOUR
' values compete for three callee-saved registers -- cstring, profile, status, t -- and t
' has the lowest cost (usage/(degree*block_count), section 22) because it is live across
' the whole loop. Remove the profile Local and only three values compete, nothing spills,
' the frame disappears and the body loses 8 bytes. So the Local must stay; the copy it
' brings with it is the price.
'
' ARITHMETIC FOR THE NEXT ATTEMPT. The no-Local form is 317. Adding `sub esp,4` (3 bytes)
' plus the four [ebp-4] accesses that grow by one byte each over their register forms (4)
' plus one byte for the receiver load moving from the 5-byte `A1` EAX form to the 6-byte
' `8B 35` ESI form gives exactly 325. So a spelling that makes `t` spill WITHOUT
' introducing a named Local receiver would land on the nose. Nothing tried so far does
' that: the fourth live value has to come from somewhere, and every source-level way of
' creating one also creates a Local.
'
' CONSEQUENCE FOR TProfile.SaveGame (0x00565D99, 845/850): it CANNOT be promoted yet.
' Rule 13.3 forbids stubbing an unverified callee to make a caller mask, and this callee is
' still unverified. The 5-byte gap in SaveGame is confirmed to be exactly this call.
'
' BUILD REQUIREMENT (new capability, wired this session): this body needs a DLL import,
' which the harness could not express before. '!Import is a new pragma -- bcc rejects
' `Import` anywhere but the top of the file, so '!Raw cannot carry one. The import library
' is generated from the SHIPPED steamstub.dll, not stubbed:
'     dlltool -m i386 -d extern/steamstub/steamstub.def -D STEAMSTUB.DLL \
'             -l extern/steamstub/libsteamstub.a
' This also unblocks TProfile.CheckAchievement, which a documentation pass independently
' reported as untestable "blocked on two Steam DLL imports the harness can't link".
'
'!Import "<repo>/extern/steamstub/libsteamstub.a"
'!Raw Extern
'!Raw Function FindLeaderboard(name:Byte Ptr)
'!Raw Function ReadSteam:Byte Ptr()
'!Raw Function UploadLeaderboardScore(mode:Int, value:Int, name:Byte Ptr)
'!Raw End Extern
'!Global g_profile_int43:Int
'!Global g_contractoffer_tplayer:TProfile
	If g_profile_int43 <> 1 Then
		Print "Steamstate offline!"
		Return 0
	EndIf
	Print "Finding leaderboard"
	Local p:Byte Ptr = "Player Value".ToCString()
	FindLeaderboard(p)
	MemFree p
	Local t:Int = MilliSecs()
	Local s:String
	Repeat
		s = String.FromCString(ReadSteam())
		If s.length > 0 Then Print s
		If s = "leaderboard:found" Then
			Local g:TProfile = g_contractoffer_tplayer
			Local q:Byte Ptr = g_contractoffer_tplayer.name.ToCString()
			UploadLeaderboardScore(2, g.GetValue(), q)
			MemFree q
		EndIf
	Until MilliSecs() > t + 2000 Or MilliSecs() < t Or s.Contains("upload")
	Print "Post end: " + (MilliSecs() - t)
	Return 0
