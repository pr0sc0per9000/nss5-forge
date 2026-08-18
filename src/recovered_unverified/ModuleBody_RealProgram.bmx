' ============================================================================
' NSS5 module body -- the REAL PROGRAM, body offset +5549..+7933 (2,384 bytes)
' VA range 0x004BB5E1 .. 0x004BBF31 (end-exclusive; 0x004BBF30 is the final RET)
' Parent function: the module body itself, 0x004BA034, 7933 bytes total.
'
' STATUS: NOT VERIFIED. This is a documented, evidence-based reconstruction, not an
' oracle MATCH. There is currently NO per-region harness: `harness.try_method` /
' `harness.try_function` verify a single Type method or module Function compiled
' alone in a synthetic probe, and this text is neither -- it is a slice of module-level
' top-level code (Global declarations interleaved with executable statements) that only
' `scripts/try_main_body.py` can build, and that tool builds the WHOLE 7,933-byte body,
' not a sub-range. Until `assemble.py` gets Incbin + all 94 Globals + this tail wired in
' (still open), this file cannot be run through the
' byte oracle at all -- there is nothing to mask a MISMATCH against. Do not move this to
' src/recovered_module/ or src/recovered/ on the strength of the reasoning below; it has
' not been byte-checked.
'
' EVERY call target below was named one of three ways, in order of confidence:
'   (1) already recovered/verified game code (LogLine, ReadSettingString, ReadSettingFloat,
'       LoadImageChecked, LoadSoundChecked, GameMain) -- per src/recovered_module/ headers.
'   (2) `helper_map.full_table()` under NSS5_NO_LEARN=1 (BRL functions / runtime helpers) --
'       _bbStringConcat, _bbGCFree, _bbObjectNew, _bbArrayNew1D, _bbFloatToInt,
'       _bbMilliSecs, _bbStringFromInt, _brl_retro_Lower/Right, _bbStringCompare,
'       _bbStringReplace, _brl_filesystem_CreateDir/WriteFile, _brl_random_SeedRnd,
'       _JoyCount, _brl_audio_SetAudioDriver/AllocChannel, _brl_graphics_GetGraphicsDriver/
'       SetGraphicsDriver, _brl_d3d7max2d_D3D7Max2DDriver, _brl_max2d_SetMaskColor,
'       _brl_max2d_AutoMidHandle (the __maxgui_localization_...|_brl_max2d_AutoMidHandle
'       alias, resolved by context -- graphics setup, not GUI localisation).
'   (3) direct evidence read from NSS5.exe this session: `extracted/class_tables.tsv` +
'       `extracted/vtable_map.tsv` identify the two "New <classtable>; call obj[+0x88]"
'       driver singletons as TD3D9Max2DDriver (0x005A1207) and TGLMax2DDriver (0x005A4CC7),
'       both via their Create():TSelf method at slot 0x88 -- confirming these are the
'       niladic BRL accessor Functions `D3D9Max2DDriver()` / `GLMax2DDriver()`. Likewise
'       0x0059812E resolves to a method call (vtable slot 0x50) on the cached
'       TWinVolumeDriver singleton at Global 0x00C9ABC0 (`extracted/globals_final.tsv`),
'       almost certainly `CurrentDir()`.
'   String literal CONTENTS were read with `harness.read_string()` directly out of the
'   .data section (not guessed) for every address below; see the disassembly trace in
'   this pass's session notes for the exact bytes.
'
' NAMES ARE OURS except where noted. Several Globals already carry a name from
' `extracted/module_globals_decoded.tsv` (auto-generated, often semantically wrong --
' e.g. g_screen_mainmenu_int26 is really the save-directory String, g_club_int07 is
' really the "fullnames" setting) -- both names are given in comments so this file cross-
' references cleanly against that TSV.
'
' TWO THINGS ARE GENUINELY UNRESOLVED, NOT GUESSED PAST:
'   (a) `Replace([g_appExeArg], " ", "%20")` (0x004BB783, see below) -- the return value is
'       provably discarded: the next instruction after `add esp,0xC` is the following
'       statement's guard test, with no intervening store or release. Either this really is
'       a source-level bare statement whose result is thrown away, or bcc's store happens
'       through a path this linear disassembly did not capture (e.g. a Field write). Left
'       as a statement with no assignment; flagged loudly rather than invented.
'   (b) `GraphicsDriver().<slot 0x18 method>()` (0x004BB0F4A + 0x18) -- the method is
'       almost certainly a name/identify accessor (ToString, per the TD3D9Max2DDriver and
'       TGLMax2DDriver vtable rows at the SAME slot 0x18), used only to build the LogLine
'       argument, but the exact BlitzMax spelling used at the call site was not confirmed
'       against `vtable_map.tsv` for whichever driver Type is active at that point.
' ============================================================================


' -- Globals with a bare, order-independent initialiser (bcc's lazy-once Global-init
'    idiom, confirmed compiler-emitted by a standalone `Global g:String[300]`
'    probe -- getting the TYPE and SIZE right is sufficient, the run-once guard follows
'    for free). Declared here; the executable statements that are NOT simple Global
'    initialisers follow in their real source-order position below. --

' g_screen_mainmenu_int26 in the auto-named TSV; really the save-data directory root.
Global g_saveDir:String = Lower(Trim(ReadSettingString(g_appDir + "Settings/Settings.txt", "saveloc")))
' -- NOTE the two globals g_appDir (0x00C6E950, corrected to String in
'    globals_corrections.tsv) and the literal "Settings/Settings.txt" (0x00C6E970) are the
'    SAME pair LoadImageChecked/ReadSettingString test as g_pathPrefix/g_dataDir; this
'    settings file is read from the game's own install directory, not the per-user saveDir.

If Right(g_saveDir, 1) <> "/" And Right(g_saveDir, 1) <> "\"
	g_saveDir = g_saveDir + "/"
EndIf
If g_saveDir.Length < 3
	' Fallback: TWinVolumeDriver's CurrentDir() (vtable slot 0x50, inferred, see header) + "\New Star Soccer 5\"
	g_saveDir = CurrentDir() + "/New Star Soccer 5/"
EndIf
CreateDir(g_saveDir, False)
CreateDir(g_saveDir + "Settings/", False)
CreateDir(g_saveDir + "Save/", False)
CreateDir(g_saveDir + "Replays/", False)

' Statement (a) from the header -- result discarded, purpose unconfirmed.
' g_misc_int61 (0x00C6EF10) is typed Int in every extracted table, but it is passed here
' as a STRING to _bbStringReplace, so the table is very likely wrong about it (same class
' of error documented in codegen-patterns.md 10.7/11.2/16.7: refcount/argument traffic
' decides the type, not the table). Left un-renamed pending confirmation.
Replace(g_misc_int61, " ", "%20")

' -- "debug"/"fullnames"/"nettimeout"/"port" all go through ReadSettingFloat(url, key,
'    clampMin, clampMax) -- confirmed against src/recovered_module/ReadSettingFloat.bmx.
'    A MISSING key returns 0.0, which the function then clamps into [clampMin,clampMax]
'    before returning -- so a missing "nettimeout" silently becomes 3.0 (clamped UP to
'    its floor), not some other implied default, and a missing "debug"/"fullnames"/"port"
'    becomes 0 (already inside their [0,x] ranges). This refines any assumption that the
'    upper clamp bound is "the default": it is the CEILING, not the fallback value. --
Global g_engine_int161:Int = Int(ReadSettingFloat(g_appDir + "Settings/Settings.txt", "debug", 0.0, 2.0))
Global g_club_int07:Int    = Int(ReadSettingFloat(g_appDir + "Settings/Settings.txt", "fullnames", 0.0, 1.0))
Global g_misc_int62:Int    = Int(ReadSettingFloat(g_appDir + "Settings/Settings.txt", "nettimeout", 3.0, 99.0))
Global g_misc_int63:Int    = Int(ReadSettingFloat(g_appDir + "Settings/Settings.txt", "port", 0.0, 100000000.0))
Global g_misc_int64:String = ReadSettingString(g_appDir + "Settings/Settings.txt", "proxy")   ' no clamp -- plain String

Global g_screen_int20:Int = MilliSecs()          ' "boot time" per docs/game/engine/main-loop.md
SeedRnd(g_screen_int20)
Global g_engine_int164:Int = JoyCount()           ' joystick count at boot

' Debug logging -- REAL control flow, not a lazy-init guard: only runs if the "debug"
' setting (just read above) is nonzero.
Local g_Object856:TStream   ' 0x00C6EFF0 -- the log-file stream, closed at the very end
If g_engine_int161 <> 0
	g_Object856 = WriteFile(g_appDir + "log.txt")
EndIf

' -- g_contractoffer_tplayer/g_engine_int167 --
' IMPORTANT CORRECTION to docs/game/engine/main-loop.md: GameMain's own pseudocode
' assumes "accumulator = 0" at boot. The actual initialiser for the accumulator
' (0x00C6F034) copies the value of the FIXED-TIMESTEP CONSTANT itself (0x00C6F02C,
' statically 25 -- this address is NOT one of the 94 lazy-init Globals; it has no guard
' of its own, consistent with it being a plain compile-time-constant initialiser baked
' straight into .data) -- so the accumulator starts at 25, equal to one full tick, not 0.
' Combined with GameMain's own decompile never re-zeroing it, the very first
' logic Update() fires immediately on the first pass through GameMain's catch-up loop,
' before the first Render() -- the world gets one tick of head start before anything is
' ever drawn. Not asserted in main-loop.md; flagged here for whoever owns that document.
Global g_contractoffer_tplayer:TProfile = New TProfile     ' 0x00C6F028
Global g_engine_int167:Int = g_timestepMs                   ' 0x00C6F034 = 0x00C6F02C (=25)

' Logs the active/default graphics driver's name before driver selection below.
LogLine(GraphicsDriver().ToString())   ' slot 0x18 -- see header note (b)

' -- Graphics driver selection. "opengl" read fresh (not reusing g_* above -- a second,
'    independent ReadSettingFloat call against the same Settings.txt). --
If ReadSettingFloat(g_appDir + "Settings/Settings.txt", "opengl", 0.0, 1.0) = 1.0
	SetGraphicsDriver(GLMax2DDriver(), 2)
Else
	' TD3D9Max2DDriver.Create():TD3D9Max2DDriver (vtable slot 0x88) can fail and return
	' Null -- the classic "try D3D9, only fall back to D3D7 on failure" idiom. Confirmed
	' by class_tables.tsv/vtable_map.tsv this session, not inferred from shape alone.
	' NOTE: on success this branch calls SetGraphicsDriver on NEITHER path explicitly --
	' the natural reading is that TD3D9Max2DDriver.Create() registers itself as the active
	' driver internally on success, which was not independently confirmed.
	If D3D9Max2DDriver() = Null
		SetGraphicsDriver(D3D7Max2DDriver(), 2)
	EndIf
EndIf

' Dead code: FUN_00596AFF's only interesting branch is gated on a
' function-typed Global that is never assigned anything but the null-function-error stub
' anywhere in the shipped binary. This call always returns 0 and has no observable effect.
FUN_00596AFF()

If Not SetAudioDriver("OpenAL")
	SetAudioDriver("FreeAudio")
	LogLine("FreeAudio")
EndIf

Global g_Object857:TChannel = AllocChannel()   ' 0x00C6F088
Global g_Object858:TChannel = AllocChannel()   ' 0x00C6F08C
Global g_Object859:TChannel = AllocChannel()   ' 0x00C6F090
Global g_Object860:TSound = LoadSoundChecked("GameMedia/Sounds/Cash.ogg", 0)          ' 0x00C6F0D4
Global g_Object861:TSound = LoadSoundChecked("GameMedia/Sounds/Achievement.ogg", 0)   ' 0x00C6F124
Global g_misc_arr03:TSound[6]                                                          ' 0x00C6F130 -- populated elsewhere

SetMaskColor(8, 132, 107)   ' classic colour-key transparency mask (r=8,g=132,b=107)
AutoMidHandle(False)

Global g_screen_achievements_int03:String = g_appDir + "GameMedia/Images/Icons/"   ' 0x00C6F170 -- icon folder, not achievements-specific despite the auto-name
Global g_Object862:TImage = LoadImageChecked(g_screen_achievements_int03 + "ArrowL.png", -1)      ' 0x00C6F194
Global g_Object863:TImage = LoadImageChecked(g_screen_achievements_int03 + "ArrowR.png", -1)      ' 0x00C6F1B8
Global g_Object864:TImage = LoadImageChecked(g_screen_achievements_int03 + "ArrowU.png", -1)      ' 0x00C6F1DC
Global g_Object865:TImage = LoadImageChecked(g_screen_achievements_int03 + "ArrowD_Red.png", -1)  ' 0x00C6F208
Global g_Object866:TImage = LoadImageChecked(g_screen_achievements_int03 + "Refresh.png", -1)     ' 0x00C6F230
Global g_Object867:TImage = LoadImageChecked(g_screen_achievements_int03 + "Cross.png", -1)       ' 0x00C6F254
Global g_Object868:TImage = LoadImageChecked(g_screen_achievements_int03 + "Tick.png", -1)        ' 0x00C6F274
Global g_Object869:TImage = LoadImageChecked(g_screen_achievements_int03 + "CrossSmall.png", -1)  ' 0x00C6F2A0
Global g_Object870:TImage = LoadImageChecked(g_screen_achievements_int03 + "TickSmall.png", -1)   ' 0x00C6F2CC
Global g_Object871:TImage = LoadImageChecked(g_screen_achievements_int03 + "Help.png", -1)        ' 0x00C6F2EC

' These two use a DIFFERENT base folder (backslashes, "Interface" not "Icons") and are
' NOT built through g_screen_achievements_int03 -- full literal paths, read straight from
' the .data section, flags differ too (-1 then 1, not both -1 like the ten icons above).
Global g_Object872:TImage = LoadImageChecked("GameMedia\Images\Interface\MessageBg.png", -1)    ' 0x00C6F34C
Global g_Object873:TImage = LoadImageChecked("GameMedia\Images\Interface\MessageLine.png", 1)   ' 0x00C6F3B0

' -- End of the guarded-Global section. Everything below is genuinely unconditional,
'    sequential, top-level code -- confirmed by the absence of any flags_word test. --

GameMain()   ' 0x004BCCDB -- never returns in normal play (main-loop.md: infinite Repeat);
             ' the rest of this function only runs if it somehow does.

If g_Object856 <> Null
	CloseStream g_Object856
EndIf

' original: `mov eax,0 / ret` -- module body always returns 0.
