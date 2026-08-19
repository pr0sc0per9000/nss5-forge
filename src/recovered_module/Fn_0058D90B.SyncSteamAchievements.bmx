' Fn_0058D90B.SyncSteamAchievements -- module-level Function (no Type). NAME IS OURS: no
' reflection record.
' VA 0x0058D90B   124 bytes (Ghidra inventory)   sig ()i
' byte-identical vs NSS5.exe (124/124, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=8), verified with harness.try_function under NSS5_NO_LEARN=1.
'
' Unattributed "code" function -- not in vtable_map.tsv, so the name is OURS per section 8 of
' the reconstruction skill, not a recovered original name. Called bare, with 0 arguments, from
' one site only: TProfile.LoadSavedGame (VA 0x005659F1, src/recovered_unverified/
' TProfile.LoadSavedGame.bmx), which already carries this name in its own placeholder Extern
' and explains, in its header, how the name and the "called from nowhere else" fact were
' established (extracted/callgraph_resolved.tsv has exactly one row for this VA as a callee).
'
' STEAM CALL -- NOT A DIVERGENCE. This function calls SetSteamAchievement, a genuine
' STEAMSTUB.DLL import thunk (0x004A9D50, extracted/dll_imports.tsv), the same one already
' linked for TProfile.CheckAchievement.bmx and Fn_0058D987.SteamPostPlayerValue.bmx via the
' '!Import + '!Raw Extern pragma pair those files establish. Unlike SteamInit (src/
' recovered_module/SteamInit.bmx), which hard-exits the process with `End` when Steam is
' unreachable and therefore has to be neutralised, this function's entire body sits behind a
' single guard on the same flag SteamInit writes: `If g_profile_int43 <> 1 Then Return 0`.
' SteamInit sets that flag to 0 (offline) unconditionally now, so the guard is never satisfied
' and the loop below -- and every Steam call inside it -- never runs. The original logic is
' therefore reproduced as written, with no behavioural change and no `End`, exactly the way
' CheckAchievement and SteamPostPlayerValue already reproduce their own Steam calls unmodified.
'
' SEMANTICS: for i = 1 To 100, if g_profile.achievements[i-1] > 0 Then build "ACHIEVEMENT_" + i
' and report it to Steam via SetSteamAchievement, freeing the C string afterwards.
'
' ASSUMPTIONS
'   g_profile_int43:Int  0x00C6F3B8 -- the Steam-enabled flag, same address SteamInit writes
'     as g_steamstate and TProfile.CheckAchievement/SteamPostPlayerValue read as
'     g_profile_int43 (scripts/explain_global.py 0x00c6f3b8: STRONG, canonical name from
'     TProfile.CheckAchievement.bmx). Named g_profile_int43 here for consistency with those
'     two sibling Steam bodies.
'   g_profile:TProfile  0x00C6F028 (STRONG, 142 bodies corpus-wide) -- the loaded profile.
'   TProfile.achievements:Int[]  offset 0x1BC (444), confirmed against
'     extracted/object_model.json and already used at this same offset in
'     TProfile.CheckAchievement.bmx.
'   0x004A7AC0 = _bbStringFromInt, 0x004A7C20 = _bbStringConcat (extracted/runtime_helpers.tsv).
'   0x004A6E20 = _bbStringToCString, 0x004A8DA0 = _bbMemFree (extracted/
'     brl_functions_inferred.tsv, both already named while recovering
'     Fn_0058D987.SteamPostPlayerValue.bmx).
'   0x004A9D50 = SetSteamAchievement, STEAMSTUB.DLL (extracted/dll_imports.tsv).
'   Literal "ACHIEVEMENT_" read at 0x00C8F0D8 (harness.read_string) -- the same text
'     TProfile.CheckAchievement.bmx builds at its own call sites.
'   Loop shape read directly from the disassembly (harness.disasm_original 0x0058D90B): the
'     guard test precedes the loop init entirely (there is no wrapping Else -- the "je"
'     target IS the loop's `mov ebx,1`), so the guard is a bare leading
'     `If g_profile_int43 <> 1 Then Return 0` with no EndIf-wrapped remainder, matching the
'     same shape already used in Fn_0058D987.SteamPostPlayerValue.bmx. The loop itself is the
'     standard init/jmp-to-check/body/increment/check `For` codegen (mov ebx,1; jmp check;
'     body; add ebx,1; check: cmp ebx,0x64; jle body) -- ordinary `For Local i:Int = 1 To 100`.
'   Argument order for the concat: `push eax(StringFromInt result)` then
'     `push 0xC8F0D8("ACHIEVEMENT_")` then `call _bbStringConcat` -- cdecl right-to-left, so
'     the literal is the first argument and the int-as-string is the second, i.e. source-level
'     `"ACHIEVEMENT_" + i`, not `i + "ACHIEVEMENT_"`.
'!Import "<repo>/extern/steamstub/libsteamstub.a"
'!Raw Extern
'!Raw Function SetSteamAchievement(name:Byte Ptr)
'!Raw End Extern
'!Global g_profile_int43:Int
'!Global g_profile:TProfile
	Function SyncSteamAchievements:Int()
		If g_profile_int43 <> 1 Then
			Return 0
		EndIf
		For Local i:Int = 1 To 100
			If g_profile.achievements[i-1] > 0 Then
				Local p:Byte Ptr = ("ACHIEVEMENT_" + i).ToCString()
				SetSteamAchievement(p)
				MemFree p
			EndIf
		Next
		Return 0
	End Function
