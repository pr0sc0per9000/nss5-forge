' SteamInit -- module-level Function (no Type). NAME IS OURS: no reflection record.
' VA 0x0058D86D   158 bytes   sig ()i
'
' ############################################################################
' # DELIBERATE DIVERGENCE FROM THE ORIGINAL.                                 #
' # A deliberate project decision, not a reconstruction bug.                 #
' ############################################################################
'
' The original body (byte-identical, 158/158, mode=reloc, verified under NSS5_NO_LEARN=1)
' is preserved verbatim at the bottom of this file; it is not compiled.
'
' WHAT THE ORIGINAL DOES
' OpenSteam(212780), and on -1 shows "Steam must be running to play this game.", logs
' "OpenSteam() failed." and calls `End`. steamstub.dll's OpenSteam returns -1 when
' SteamAPI_Init fails, which is whenever Steam did not start the game. Run outside Steam,
' the retail path ends the process before the first frame.
'
' WHAT THIS ONE DOES
' Calls OpenSteam from extern/steamstub/steamnull.c, which forwards to the game's own
' steamstub.dll only when Steam started the game (SteamAppId is set) and that DLL sits
' beside the exe; otherwise it answers 0, the original's "Steam is offline" state. The
' result goes in g_steamstate (0x00C6F3B8, unified with g_profile_int43, which
' TProfile.CheckAchievement tests for 1). It never calls `End`: -1 is just not online.
' So launched from Steam (the mod loader), achievements reach Steam; run anywhere else,
' the build behaves exactly as the old stub did and STEAMSTUB.DLL is never loaded.
'
' WHY GameMain WAS NOT TOUCHED
' GameMain (0x004BCCDB, 484/484) is byte-verified and calls SteamInit() as the very first
' thing the program does. Changing the callee instead of the caller keeps GameMain
' byte-exact, so exactly one body in the whole corpus diverges from the original.
'
' This file is not covered by scripts/reverify.py (that tool scans src/recovered/ for
' `Type.Method.bmx` names only), so it will NOT be flagged as a regression. Recording the
' divergence here is therefore the only thing that keeps it honest.
'
' The Extern lines carry trailing comments to keep their text unique: harness.merge_globals
' dedupes '!Raw payloads by text (see Fn_0058D987.SteamPostPlayerValue.bmx BUILD NOTE).
'!Import "<repo>/extern/steamstub/steamnull.c"
'!Raw Extern ' SteamInit
'!Raw Function OpenSteam:Int(appid:Int)
'!Raw End Extern ' SteamInit
'!Global g_steamstate:Int = -1
	Function SteamInit:Int()
		' 1 only when Steam started the game. See the header.
		g_steamstate = OpenSteam(212780)
		Return 0
	End Function

' ============================================================================
' ORIGINAL BODY, byte-identical to NSS5.exe (158/158). Kept for reference and
' for anyone restoring Steam support. Do not uncomment without also restoring
' the '!Import and '!Raw Extern pragmas listed in the header.
'
'	Function SteamInit:Int()
'		g_steamstate = OpenSteam(212780)
'		If g_steamstate = -1
'			Notify("Steam must be running to play this game.", 0)
'			LogLine("OpenSteam() failed.")
'			End
'		EndIf
'		Select g_steamstate
'			Case 1
'				LogLine("Steam is online")
'			Case 0
'				LogLine("Steam is offline")
'			Default
'				LogLine("steamstate=" + g_steamstate)
'		End Select
'		Return 0
'	End Function
' ============================================================================
