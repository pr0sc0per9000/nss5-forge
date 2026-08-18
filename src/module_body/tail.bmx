' ============================================================================
' NSS5 module body -- THE REAL PROGRAM. Body offset +5549..+7933 (2,384 bytes),
' VA 0x004BB5E1 .. 0x004BBF31. This is what actually runs at start-up, and it
' ends by calling GameMain().
'
' Derived from src/recovered_unverified/ModuleBody_RealProgram.bmx (the READ
' reconstruction, whose header carries the full per-call evidence trail). Read
' that file for WHY each call is named what it is; this file is the compilable
' form of the same thing.
'
' TWO STRUCTURAL DIFFERENCES FROM THAT FILE, both deliberate:
'
'  1. NO `Global` DECLARATIONS HERE -- only assignments. Every Global this code
'     touches is declared once by assemble.py, which merges three sources: the
'     '!Global pragmas carried by recovered bodies, the 64 array Globals decoded
'     from the exe (extracted/module_globals_decoded.tsv), and
'     src/module_body/globals.tsv for the rest. Declaring them here as well
'     would be a duplicate-identifier build error, since 6 of them are already
'     emitted from recovered bodies' pragmas.
'
'     COST, stated plainly: `Global g:T = expr` at module scope makes bcc emit a
'     run-once lazy-init guard, and a bare assignment does not. For a program
'     that executes this block exactly once, top to bottom, the behaviour is
'     identical -- but the BYTES are not. This file is therefore not a candidate
'     for byte-matching the module body as written. That is the accepted trade
'     (boot first). Byte-matching the module body needs the
'     declaration form restored and assemble.py emitting Types and Globals
'     interleaved per extracted/module_emission_order.tsv.
'
'  2. `FUN_00596AFF()` IS NOT CALLED. Measured: the game's own
'     function universe is 0x004c17e2..0x0058b918, and both 0x00596AFF (194 B)
'     and its callee 0x00595EF3 (210 B) sit ABOVE that ceiling, adjacent to
'     brl.openalaudio's module initialiser. They are BRL library code, present in
'     no game inventory (coverage_sweep.tsv, probeability.tsv, work_units.tsv all
'     lack them), and our toolchain emits them from BRL's own sources. This pair is
'     not a reconstruction blocker. Independently, the only interesting branch
'     inside 0x00596AFF is dead in the shipped binary -- its guard tests a function-typed
'     Global that is never assigned anything but the null-function-error stub, so
'     the call always returns 0 with no observable effect. Omitting it is
'     behaviour-preserving on both counts.
'
' Steam is stripped, but that happens in SteamInit itself, not
' here -- GameMain still calls it and stays byte-exact.
' ============================================================================

' ############################################################################
' # TEMPORARY BOOT TRACE. Plain Print, not LogLine -- LogLine is a no-op until
' # g_logstream is opened partway down this file, and the first failure may
' # happen before that. Strip these once the boot is stable.
' ############################################################################
Print "[boot] module body entered"

' ---- current language ---------------------------------------------------------
' 0x00C5A33C. TLocale.GetLocaleText.bmx's header records this slot as "statically
' initialised to 'en'", i.e. it is one of the 30 module Globals that carry a real
' initialiser and were never decoded into module_globals_decoded.tsv. Without it the
' first GetText() before the language picker runs looks up Null in the locale map.
' (globals_final.tsv types this address Int; the code passes it to ValueForKey(:Object)
' and assigns string literals to it, so the table is wrong and String is right --
' GetLocaleText.bmx says as much.)
g_locale_lang = "en"

' ---- install directory --------------------------------------------------------
' g_dataDir is 0x00C6E950: the base every relative asset path is resolved against
' by LoadImageChecked / LoadSoundChecked / ReadSettingString / ReadSettingFloat
' (14 recovered bodies declare it via '!Global). Nothing in the corpus ever
' ASSIGNS it, so it is set here, in the module body.
' AppDir is BlitzMax's own "directory the executable lives in", which is what the
' retail game resolves GameMedia/ and Settings/ against.
g_dataDir = AppDir + "/"

' ---- save directory -----------------------------------------------------------
' Retail Settings.txt ships `saveloc=0`, so ReadSettingString returns "0", which
' is 1 character and trips the Length < 3 fallback below. The configured-path
' branch is therefore dead for a stock install, but preserved.
Print "[boot] reading saveloc"
g_savedir = Lower(Trim(ReadSettingString(g_dataDir + "Settings/Settings.txt", "saveloc")))
If Right(g_savedir, 1) <> "/" And Right(g_savedir, 1) <> "\"
	g_savedir = g_savedir + "/"
EndIf
If g_savedir.length < 3
	g_savedir = CurrentDir() + "/New Star Soccer 5/"
EndIf

' g_pathPrefix (0x00C6E9A8) is the OTHER half of the pair the asset loaders test:
' LoadImageChecked does `If Not a0.Contains(g_pathPrefix) And Not a0.Contains(g_dataDir)
' Then a0 = g_dataDir + a0`, i.e. "if this path is under neither the save root nor
' the install root, make it install-relative". The auto-generated tables name this
' slot g_screen_mainmenu_int26 and type it Int; ModuleBody_RealProgram.bmx's header
' records that it is really the save-data root, which is what it is set to here.
' If g_pathPrefix and g_savedir turn out to be the same slot under two recovered
' names (the same latent hazard as g_inpname), assigning both the same value is
' correct either way.
' g_pathPrefix must not be assigned from g_savedir: that is a real latent bug, not a
' cosmetic one.
'
' 0x00C6E950 is the INSTALL-path prefix, not the save root. Three names for it and 103
' references in the assembled program: g_pathPrefix (THorse.Create.bmx:21 "the same slot
' every asset-loader in the corpus uses"; TCard.CreateCard.bmx:4 "the install-path
' prefix"), g_datapath (TFormation.LoadTactics.bmx:5 "the install/EngineMedia root path";
' TClub.SaveMaster, TCompetition.LoadData, TEngine.SetUp), and the auto-generated
' g_promotionplace_int05 that the alias map unifies them onto.
'
' TLocale.SetUp reads it directly:
'     ReadFile("utf8::" + g_datapath + "GameMedia/Languages/Languages.csv")
' and hard-exits via Notify + End if that file is missing -- there is no English fallback.
' With the save root in there, that path was wrong, and the ONLY reason the game booted at
' all is that a Null String concatenates as empty, leaving a RELATIVE path that happens to
' resolve when the working directory is the exe directory. Launch the game from anywhere
' else -- a desktop shortcut, a debugger, a test harness -- and it dies on the language
' file before drawing a frame. The automated screen sweep hit exactly that and stopped
' after two lines.
'
' 0x00C6E9A8 (g_dataDir) is set to the same install root just above, which is what makes
' LoadImageChecked/LoadSoundChecked resolve GameMedia/... correctly. The SAVE root stays in
' g_savedir and is used only for Save/, Replays/ and Settings/ under the user's directory.
g_pathPrefix = g_dataDir

Print "[boot] creating save dirs"
CreateDir(g_savedir, False)
CreateDir(g_savedir + "Settings/", False)
CreateDir(g_savedir + "Save/", False)
CreateDir(g_savedir + "Replays/", False)

' NOTE -- one statement from the original is intentionally absent here:
'   Replace(<0x00C6EF10>, " ", "%20")
' Its result is provably discarded (the next instruction after `add esp,0xC` is the
' following statement's guard test, with no store or release between). The Global it
' reads is typed Int in every extracted table yet passed to _bbStringReplace as a
' String, so the tables are wrong about it and the correct declaration is unknown.
' A statement with no effect and an unresolved operand type is not worth a build
' error; recorded rather than guessed. See ModuleBody_RealProgram.bmx header note (a).

' ---- Settings.txt values ------------------------------------------------------
' ReadSettingFloat(url, key, clampMin, clampMax). A MISSING key returns 0.0 and is
' then clamped INTO the range -- so absent "nettimeout" becomes 3.0 (clamped up to
' its floor), not 99. The upper bound is a ceiling, not a default.
Print "[boot] reading Settings.txt values"
g_engine_int161 = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "debug", 0.0, 2.0))
g_club_int07    = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "fullnames", 0.0, 1.0))
g_misc_int62    = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "nettimeout", 3.0, 99.0))
g_misc_int63    = Int(ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "port", 0.0, 100000000.0))
g_misc_int64    = ReadSettingString(g_dataDir + "Settings/Settings.txt", "proxy")

Print "[boot] seeding RNG"
g_screen_int20 = MilliSecs()
SeedRnd(g_screen_int20)
Print "[boot] JoyCount"
g_engine_int164 = JoyCount()

' ---- debug log ----------------------------------------------------------------
' Real control flow, not a lazy-init guard: only opens if "debug" is nonzero.
' Retail ships debug=0, so this is closed by default.
Print "[boot] opening debug log"
If g_engine_int161 <> 0
	g_logstream = WriteFile(g_dataDir + "log.txt")
EndIf

' ---- the fixed-timestep clock -------------------------------------------------
' 0x00C6F02C is statically 25 (40 Hz) and has no lazy-init guard of its own -- a
' plain compile-time constant baked into .data.
'
' This contradicts docs/game/engine/main-loop.md: the accumulator (0x00C6F034) is
' initialised to the value of the timestep constant, NOT to 0. GameMain never
' re-zeroes it. So the very
' first logic Update() fires immediately on the first pass through the catch-up loop,
' before the first Render() -- the world gets one tick of head start before anything
' is drawn. main-loop.md's pseudocode assumes accumulator = 0 and is wrong on this.
Print "[boot] timestep + TProfile"
g_timestepMs = 25
' g_profile, NOT g_contractoffer_tplayer. ModuleBody_RealProgram.bmx names this slot
' g_contractoffer_tplayer, but extracted/globals_type_overrides.tsv retired that name:
' 0x00C6F028's construction site is `push 0x00C6A4C0; call bbObjectNew` and 0x00C6A4C0 is
' TProfile's class table, and the corpus majority (plus GameMain's own '!Global pragma)
' spells it g_profile. Assigning the retired name would have created the TProfile into a
' Global nothing reads, leaving the one GameMain uses Null.
g_profile = New TProfile
g_engine_int167 = g_timestepMs

' ---- graphics driver ----------------------------------------------------------
' brl.graphics spells this GetGraphicsDriver, not GraphicsDriver
' (graphics.mod/graphics.bmx:145) -- ModuleBody_RealProgram.bmx used the shorter
' name, which does not exist. The underlying symbol recorded for it,
' _brl_graphics_GetGraphicsDriver, was right all along.
Print "[boot] GetGraphicsDriver().ToString()"
LogLine(GetGraphicsDriver().ToString())

' "opengl" is read FRESH here -- a second, independent ReadSettingFloat against the
' same file, not a reuse of any value above. Retail ships opengl=0, so the stock
' path is the D3D9-then-D3D7 cascade.
Print "[boot] graphics driver select"
If ReadSettingFloat(g_dataDir + "Settings/Settings.txt", "opengl", 0.0, 1.0) = 1.0
	SetGraphicsDriver(GLMax2DDriver(), 2)
Else
	' TD3D9Max2DDriver.Create() can return Null; D3D7 is the fallback. On success the
	' natural reading is that Create() registers itself as the active driver, which
	' was never independently confirmed -- flagged in the source file's header.
	' Windows 11 note: D3D7 is the likely casualty of the three. If both D3D paths
	' fail, set opengl=1 in Settings.txt to take the GL branch instead.
	If D3D9Max2DDriver() = Null
		SetGraphicsDriver(D3D7Max2DDriver(), 2)
	EndIf
EndIf

' ---- audio driver -------------------------------------------------------------
Print "[boot] audio driver select"
If Not SetAudioDriver("OpenAL")
	SetAudioDriver("FreeAudio")
	LogLine("FreeAudio")
EndIf

Print "[boot] alloc channels"
g_Object857 = AllocChannel()
g_Object858 = AllocChannel()
g_Object859 = AllocChannel()
Print "[boot] loading sounds"
g_Object860 = LoadSoundChecked("GameMedia/Sounds/Cash.ogg", 0)
g_Object861 = LoadSoundChecked("GameMedia/Sounds/Achievement.ogg", 0)

' ---- 2D setup -----------------------------------------------------------------
Print "[boot] 2D setup"
SetMaskColor(8, 132, 107)
AutoMidHandle(False)

' ---- pre-loaded UI images -----------------------------------------------------
Print "[boot] loading UI images"
' 0x00C6F170 -- the icons root. THREE names in the corpus for this one slot:
'   g_iconpath                   -- canonical as of 2026-08-15; 10 files renamed to it
'                                   (9 that said g_mediapath, 1 that said g_ach_imgpath)
'   g_screen_achievements_int03  -- the decoder's VA-derived auto-name; misleading, it is
'                                   the general icon root, not achievements-specific
' They are still separate Globals in this build, so both must be set. Renaming the
' remaining auto-name out of the corpus is follow-up work, not a boot blocker.
g_iconpath = g_dataDir + "GameMedia/Images/Icons/"
g_screen_achievements_int03 = g_iconpath

' 0x00C6E950 -- the install root. Its other corpus spellings (g_datapath, g_skinpath, and
' g_mediapath in the NINE files that mean this slot rather than the icons one) are all
' distinct Globals here for the same reason, so each needs the same value.
g_datapath  = g_dataDir
g_skinpath  = g_dataDir
g_mediapath = g_dataDir
g_Object862 = LoadImageChecked(g_screen_achievements_int03 + "ArrowL.png", -1)
g_Object863 = LoadImageChecked(g_screen_achievements_int03 + "ArrowR.png", -1)
g_Object864 = LoadImageChecked(g_screen_achievements_int03 + "ArrowU.png", -1)
g_Object865 = LoadImageChecked(g_screen_achievements_int03 + "ArrowD_Red.png", -1)
g_Object866 = LoadImageChecked(g_screen_achievements_int03 + "Refresh.png", -1)
g_Object867 = LoadImageChecked(g_screen_achievements_int03 + "Cross.png", -1)
g_Object868 = LoadImageChecked(g_screen_achievements_int03 + "Tick.png", -1)
g_Object869 = LoadImageChecked(g_screen_achievements_int03 + "CrossSmall.png", -1)
g_Object870 = LoadImageChecked(g_screen_achievements_int03 + "TickSmall.png", -1)
g_Object871 = LoadImageChecked(g_screen_achievements_int03 + "Help.png", -1)

' These two use a different folder ("Interface", backslashes) and different flags
' (-1 then 1), read straight from .data -- not built through the icon root above.
g_Object872 = LoadImageChecked("GameMedia\Images\Interface\MessageBg.png", -1)
g_Object873 = LoadImageChecked("GameMedia\Images\Interface\MessageLine.png", 1)

' ---- shared UI colour globals -------------------------------------------------
' NOT RECOVERED -- INFERRED. Tagged honestly because docs/RULES.md draws the line at
' exactly this: we did not read these values out of NSS5.exe, we deduced them.
'
' g_col_highlight (0x00C6E91C) is read in 77 places and written NOWHERE in the corpus
' (scripts/find_dead_globals.py). Its writer is one of the functions still missing. A
' String Global that is never written is Null, and TScreen_Options.RefreshButtons does:
'       b.SetColour("FFFFFF", "FFFFFF")                       ' unselected
'       If <option is selected> Then b.SetColour(g_col_highlight, "FFFFFF")
' so with it Null every SELECTED option renders BLACK. That is visible on screen and was
' reported as "the black colour is meant to be green".
'
' "00FF00" is the best-evidenced value available without recovering the writer:
'   * it is the corpus's dominant green -- 135 literal uses, 4th most common colour of any
'     kind after white, black and mid-grey;
'   * the same screens that pass g_col_highlight to TTable.AddColumn build those very
'     tables with a literal "00FF00" (TScreen_Stats.CreateScreen lines 131/136, and the
'     same pairing in TScreen_Finances.CreateScreen and TScreen_Shop.SetUpScreen);
'   * green matches the retail game.
' Reading 0x00C6E91C out of the exe returns nothing -- the slot holds no static string, so
' it genuinely is assigned at runtime and there is no byte to recover here. If the writer
' is recovered later and disagrees, THAT wins and this line goes.
g_col_highlight = "00FF00"

' g_col_key (the control-binding label colour, used across TScreen_Controls) is written
' nowhere either. Left at the same green for now: it labels key names on the Edit Controls
' screen and Null would render them black on a dark panel, i.e. invisible.
g_col_key = "00FF00"

' ---- function-pointer Globals that nothing assigns -----------------------------
' g_opt_refresh is declared `Int()` and CALLED from six TScreen_Options.Button* handlers
' (BossFx, Distance, HighlightBall, ShowEnergy, ToolTips, Currency) -- and assigned
' nowhere in the corpus. That is not a harmless Null: in BlitzMax an UNASSIGNED function
' pointer does not hold 0, it holds a pointer to the runtime's NullFunctionError thrower
' (the same holds for every function-typed slot: an unassigned function value
' defaults to a pointer to this error-thrower, exactly like Null does for objects).
' So `If fn` tests TRUE and calling it throws immediately. That is the reported "button
' tips off instantly crashes", "distance yards/metres instantly crashes", and the rest.
'
' It is a MIS-RECOVERED CLASS-TABLE CALL, not a real function-pointer variable. Every one
' of those six handlers ends by refreshing the Options screen, and the sibling handlers
' (e.g. TScreen_Options.ButtonDifficulty) end with a
' plain `RefreshButtons()`. bcc compiles `TScreen_Options.RefreshButtons()` to
' `call dword ptr [classtable+slot]` -- the same free mechanism used for the
' whole boot sequence -- and a decompile of that reads exactly like an indirect call
' through a Global. Pointing it at the real Function restores the intended behaviour.
g_opt_refresh = TScreen_Options.RefreshButtons

' STILL DEAD, deliberately not guessed at (scripts/find_dead_globals.py finds them):
'   g_league_setround:Int(a:Int)  called from TScreen_Leagues.ButtonRound  -- no
'       TScreen_Leagues.SetRound exists in the corpus to point it at.
'   g_kits_quitfn:Int()           called from TScreen_Kits.ButtonQuit
'   g_fnaccept / g_fnnegotiate / freject
' Each still throws on call. Assigning them a no-op would silence the crash while silently
' doing nothing, which is worse than a loud failure -- it would hide the missing body.

' ---- go ------------------------------------------------------------------------
' Never returns in normal play: GameMain is an infinite fixed-timestep loop that
' only exits via the window-close predicate.
Print "[boot] CALLING GameMain"
GameMain()
Print "[boot] GameMain returned"

If g_logstream <> Null
	CloseStream g_logstream
EndIf
