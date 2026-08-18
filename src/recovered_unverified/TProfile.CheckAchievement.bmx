' TProfile.CheckAchievement -- NOT YET SCORED under this rewrite (previous drafts of this file
' were hard-excluded from scripts/assemble.py's UNVERIFIED_SKIP set, so status/score/*.txt's
' "ours" bytes are a 14-byte placeholder stub, not a real build of any prior version of this
' body -- see assemble.py lines ~87-100 for the exclusion reasons, both fixed below).
' VA 0x0056cf70   625 bytes   vtable slot 0x150   sig (i)i
'
' CHANGES THIS PASS (two real bugs fixed, not just cosmetics):
'
' 1. STEAM DLL LINK BLOCKER -- RESOLVED. Earlier drafts
'    correctly identified GetSteamAchievement
'    (0x004a9d38) / SetSteamAchievement (0x004a9d50) as genuine STEAMSTUB.DLL import thunks,
'    but had no way to link them, and worked around it with a bare `Extern ... End Extern`
'    block written as ordinary body statements. That is malformed for this project's
'    assembler/harness: '!Import/'!Raw are pragmas stripped and hoisted BEFORE the body is
'    dropped into a generated `Method ... End Method` wrapper (see harness.py's build_source /
'    assemble.py's per-file emission) -- a literal `Extern`/`End Extern` inside the body landed
'    as an orphan `End Extern` mid-method, and assemble.py's UNVERIFIED_SKIP hard-excluded this
'    file outright because of it. The '!Import + '!Raw Extern pragma pair now exists precisely
'    for this (wired for Fn_0058D987.SteamPostPlayerValue.bmx, which also unblocked this file --
'    see that file's header) and is used below the same way that file uses it.
'
' 2. THE EXTRA REFERENCE-RELEASE -- FIXED (the near-miss verdict for
'    "TProfile.CheckAchievement"). Writing the one-time icon load as an ordinary
'    `If (flag & 2) = 0 Then Global = LoadImageChecked(...) ; flag = flag Or 2 End If` --
'    standard bcc codegen for a guarded REASSIGNMENT of a refcounted Global always emits
'    retain-new + release-old. The original's bytes are retain-ONLY (no release, no visible
'    second guard): that is bcc's `Block::initGlobalRef` path for a true
'    `Global x:Type = <non-constant-expr>` DECLARATION (no prior value exists to release, so
'    none is emitted; bcc still emits its own hidden once-only bit guard around it). The
'    nearmiss write-up empirically confirmed rewriting this as a bare declaration collapses the
'    diff from +20 bytes to ~nothing, so that is what is written below -- no hand-written
'    If/flag Global at all; `g_profile_int44` was never a real game flag, it was bcc's own
'    synthesized guard bit for exactly this pattern (misnamed corpus-wide, per the write-up's
'    "surprises" section) and is not declared here.
'    NOTE the DoProgressBar near-miss tried the superficially similar fix but nested the
'    `Global = Expr` INSIDE an existing `If...EndIf`, which this toolchain scopes to that block
'    only (`Identifier ... not found` outside it) -- infeasible there. This body's guard is bcc's
'    OWN hidden one, generated from a bare top-level declaration, not a hand-written block, so
'    that trap does not apply here.
'
' GLOBALS -- renamed to the corpus's established canonical names (python scripts/
' explain_global.py <addr>, cross-checked against byte-verified src/recovered/ siblings that
' already touch the same addresses):
'   0x00c6f170  g_iconpath:String        (was g_screen_achievements_iconpath -- WRONG name;
'                                          CERTAIN, 14 bodies, e.g. TScreen_Home.CreateScreen's
'                                          identical `LoadImageChecked(g_iconpath + "Star.png",
'                                          -1)`, byte-verified)
'   0x00c8f0a4  g_Object878:TImage       (LOW-confidence placeholder name in globals_final.tsv,
'                                          but unresolved elsewhere -- no better candidate exists;
'                                          now a real `Global ... = ...` declaration, see above)
'   0x00c6f3b8  g_profile_int43:Int      (Steam-enabled flag; unresolved elsewhere, kept)
'   0x00c61724  g_screen_mousex:Float    (was g_screen_float01 -- confirmed via byte-verified
'   0x00c61728  g_screen_mousey:Float     was g_screen_float02 -- TGadget.UpdateToolTip.bmx,
'                                          which touches both these exact addresses)
'   0x00c6efe0  g_screen_width:Int       (was g_screen_int22 -- STRONG, TScreen_Kits/
'                                          TScreen_Pairs/TSlotMachine.CreateScreen/DoPrize;
'                                          NOT the same address as g_screen_w/0x00c6efe4)
'   0x00c5b1fc  g_player_int01:Int       (hand-verified project-wide, globals_corrections.tsv;
'                                          semantically match-state, but this is the established
'                                          name -- 42 bodies, byte-verified TBall.Kick.bmx uses
'                                          it identically)
'   0x00c6efe8  g_engine_int163:Int      (byte-verified TBall.Kick.bmx uses this exact name for
'                                          this exact address in this exact idiom --
'                                          `TScreenMessage.CreateAlert(10, g_engine_int163-60,
'                                          ...)` for a player-status popup, identical shape to
'                                          this function's controller-mode override)
'   0x00c6f124  g_Object861:TSound       (PlaySound arg1; unresolved elsewhere, kept)
'   0x00c6f090  g_channel:TChannel       (was g_Object859 -- LOW-confidence placeholder;
'                                          explain_global.py resolves this address to 11
'                                          candidate names all CERTAIN, `g_channel` has the most
'                                          corroborating bodies (4) and is the alias-unification
'                                          table's canonical target, extracted/
'                                          global_alias_unified.tsv)
' String literals (harness.read_string, not guessed): "CheckAchievement:", "Star.png",
'   "Bugged Achievement", "ACHIEVEMENT_", "CACHIEVEMENT_", "666666", "FFFFFF" (the last two
'   confirmed again independently in TBall.Kick.bmx's header at these same two addresses).
' Float constants read directly from .rdata: 0x00c8f0fc = 10.0 (0x41200000), 0x00c8f100 = 118.0
'   (0x42EC0000). Per TGadget.UpdateToolTip.bmx's measured note, every Float->Int narrowing in
'   this idiom goes through the implicit `_bbFloatToInt` bcc inserts for a `Local x:Int = <float
'   expr>` -- no explicit Int() in the source.
' TScreenMessage.CreateAlert(i,i,$,i,$,$,:TImage,i,i,i,i,i)i is TScreenMessage+0x48 in the class
'   table (0x00c6b27c); its 12-argument call here is the exact idiom already byte-verified in
'   TBall.Kick.bmx (`CreateAlert(x, y, GetText(...), 2500, "666666", "FFFFFF", image, 3, 0, 0,
'   0, 1)`) -- Ghidra's decompile merges most of these into the PRECEDING GetText/concat call's
'   argument list (codegen-patterns.md's documented merge trap), reconstructed here from that
'   established sibling shape, not from Ghidra's printed arg list.
' Fields: TProfile.achievements = Int[] @ offset 444 (0x1bc); TProfile.date:TMyDate @ offset 16
'   (0x10); TMyDate.sdate:Int @ offset 8 -- all confirmed against extracted/object_model.json.

'!Import "<repo>/extern/steamstub/libsteamstub.a"
'!Raw Extern
'!Raw Function GetSteamAchievement:Int(name:Byte Ptr)
'!Raw Function SetSteamAchievement(name:Byte Ptr)
'!Raw End Extern
'!Global g_iconpath:String
'!Global g_profile_int43:Int
'!Global g_player_int01:Int
'!Global g_engine_int163:Int
'!Global g_Object861:TSound
'!Global g_channel:TChannel

	LogLine("CheckAchievement:" + a0)
	Global g_Object878:TImage = LoadImageChecked(g_iconpath + "Star.png", -1)
	If a0 = 1 Or a0 = 73 Or a0 = 74 Or a0 = 75
		LogLine("Bugged Achievement")
		Local steamResult:Int = 0
		If g_profile_int43 = 1
			Local p:Byte Ptr = ("ACHIEVEMENT_" + a0).ToCString()
			steamResult = GetSteamAchievement(p)
			MemFree p
		End If
		Local gotIt:Int = False
		If steamResult <> 0
			gotIt = achievements[a0-1] > 0
		End If
		If gotIt Then Return 0
	Else If achievements[a0-1] > 0
		Return 0
	End If
	achievements[a0-1] = date.sdate
	Local x:Int = g_screen_mousex + 10.0
	Local y:Int = g_screen_width + g_screen_mousey - 118.0
	If g_player_int01 <> 0
		x = 10
		y = g_engine_int163 - 60
	End If
	If a0 <> 80
		TScreenMessage.CreateAlert(x, y, GetText("CACHIEVEMENT_" + a0), 2500, "666666", "FFFFFF", g_Object878, 3, 0, 0, 0, 1)
		PlaySound(g_Object861, g_channel)
	End If
	If g_profile_int43 = 1
		Local q:Byte Ptr = ("ACHIEVEMENT_" + a0).ToCString()
		SetSteamAchievement(q)
		MemFree q
	End If
	Return 0
