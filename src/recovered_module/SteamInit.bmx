' SteamInit -- module-level Function (no Type). NAME IS OURS: no reflection record.
' VA 0x0058D86D   158 bytes   sig ()i
'
' ############################################################################
' # DELIBERATE DIVERGENCE FROM THE ORIGINAL -- Steam stripped entirely.      #
' # A deliberate project decision, not a reconstruction bug.                 #
' ############################################################################
'
' The original body (byte-identical, 158/158, mode=reloc, verified under NSS5_NO_LEARN=1)
' is preserved verbatim at the bottom of this file; it is not compiled.
'
' WHY THIS IS A NO-OP NOW
' The retail function opened a connection to Steam (AppID 212780) and, on -1, showed
' "Steam must be running to play this game.", logged "OpenSteam() failed." and called
' `End` -- the process died right there. Steam's 2011 backend for this AppID is gone, so
' the retail path is now an unconditional hard-exit before the first frame. This is the
' single thing that would stop first boot (docs/game/engine/main-loop.md).
'
' WHAT WAS REMOVED, AND WHY IT IS SAFE
'  * The `'!Import ".../libsteamstub.a"` pragma and the `'!Raw Extern OpenSteam` block.
'    That is the whole Steam link surface for the assembled program; with these gone the
'    build does not reference steamstub at all. Verified: no file under
'    src/recovered/ or src/recovered_module/ mentions OpenSteam other than this one, and
'    GameMain's only involvement is the single `SteamInit()` call below.
'  * `g_steamstate` is KEPT and set to 0. Grepped this session: nothing anywhere in
'    src/recovered/ or src/recovered_module/ ever reads it, so the value is inert -- but
'    0 is the original's "Steam is offline" state, which is the benign branch the retail
'    game itself took when Steam was reachable but not logged in. If a body is recovered
'    later that does read it, offline is the behaviour-preserving answer.
'
' WHY GameMain WAS NOT TOUCHED
' GameMain (0x004BCCDB, 484/484) is byte-verified and calls SteamInit() as the very first
' thing the program does. Neutralising the callee instead of editing the caller keeps
' GameMain byte-exact, so exactly one body in the whole corpus diverges from the original
' rather than two. Restoring Steam later means restoring this file alone.
'
' This file is not covered by scripts/reverify.py (that tool scans src/recovered/ for
' `Type.Method.bmx` names only), so it will NOT be flagged as a regression. Recording the
' divergence here is therefore the only thing that keeps it honest.
'!Global g_steamstate:Int
	Function SteamInit:Int()
		' Steam stripped -- see the header. 0 = the original's "offline" state.
		g_steamstate = 0
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
