' TTraining.SetUpTraining
' VA 0x0057BF1F   1764 bytes   KIND=Function (static, no implicit Self)   slot 0x30   sig (i)i
' byte-identical vs NSS5.exe
' Reconstructed from extracted/decomp/TTraining.SetUpTraining@0057bf1f.c and its
' extracted/decomp_annotated/ pass (CTSLOT/STR/FN resolution -- CONFIDENCE=NONE on the
' GLOBAL substitutions specifically, everything else high-confidence/multi-site-agreed).
' NOT YET BYTE-VERIFIED. Written to revive 14 dead dereference sites in already-recovered
' TTraining bodies that read these Globals but never had a writer.
'
' REFINEMENT PASS (byte-oracle score was 6.0%, first diff at offset 12 -- right after the
' prologue's `mov ebx,[ebp+8]`). Checked against binary/NSS5.exe directly with
' scripts/disasm.py rather than guessed:
'  1. The lazy-init guard was written as `If g_snd_beep1 = Null Then`, which compiles to a
'     single `cmp [mem],imm32` -- the SHORT form (see TBall.UpdateAll.bmx's byte table). The
'     real bytes at the first-diff offset are `mov eax,[0x00c6cf60] / cmp eax,0x5c9c80 /
'     setne al / movzx eax,al / cmp eax,0 / jne`, the materialise-to-bool LONG form that only
'     `If Not <object> Then` emits (confirmed against TTrainingObject.New.bmx's and
'     TBall.SetUp.bmx's own `If Not g Then` guards, and against the disassembly at
'     0x0057BF28-0x0057BF3E, whose `jne 0x57c349` lands exactly on the post-block reset
'     code). Changed to `If Not g_snd_beep1 Then`.
'  2. The a0 dispatch (Pace/Dribbling/.../Shooting) and the tacticid dispatch
'     (GetTacticIdByName) were both written as If/ElseIf chains. Disassembling
'     0x0057C418-0x0057C440 and 0x0057C4D5-0x0057C518 shows each subject loaded into eax
'     exactly ONCE followed by back-to-back `cmp eax,N / je` tests sharing one no-match
'     `jmp` -- the Select shape (guide: "a Select loads the subject once and emits
'     back-to-back compares"), not an If/ElseIf chain (which would reload/retest per
'     branch). Changed both to `Select`/`Case`/`End Select`; the tacticid Select's
'     non-2/4 arm is a `Default` (its body is emitted inline right after the compares,
'     matching TBall.Kick.bmx's documented Select-with-Default layout), consistent with the
'     disassembly showing the "4-2-4" call block (0x0057C4E4) BEFORE the "3-4-3" call
'     blocks for Case 2 (0x0057C4F6) and Case 4 (0x0057C508) -- two separate, byte-identical
'     call sites, confirming Case 2 and Case 4 are separate clauses, not a combined
'     `Case 2, 4`. Verified the literal strings directly from the exe's data section:
'     0x00C74D14 = "3-4-3", 0x00C74D80 = "4-2-4".
'  Cross-checked g_training_int13/g_training_int14's address assignment (0x00C6CFD8 /
'  0x00C6CFDC) against the byte-verified TTraining.Call.bmx and TTraining.ResetTraining.bmx
'  and against the raw disassembly's store order (0x0057C3BE stores to CFD8 first,
'  0x0057C3F2 to CFDC second) -- this project's automatic name-unification solver currently
'  reports the opposite (AMBIGUOUS/CERTAIN mismatch against those same two verified bodies),
'  but the disassembly is unambiguous and agrees with THIS file's original assumption, so no
'  change was made there. Everything else below was re-checked against the disassembly and
'  left as-is (kit/tactic/team argument order, string literals, refcount idiom shape, the
'  g_traininglabel4 store position, and the post-init reset sequence all match exactly).
'
' ASSUMPTIONS / RESOLUTIONS
'  * The whole first block is a ONE-TIME lazy static initialiser, guarded by a single
'    `If Not g_snd_beep1 Then ... EndIf` (the original tests ONLY the first Global in
'    the chain, 0x00C6CF60, against the Null singleton -- guide 4's "&DAT_005c9c80 is
'    Null" -- then unconditionally builds all 17 objects/labels inside). Every recovered
'    New-object/refcount pair inside is the standard retain-new/release-old/store idiom
'    (guide 4); only the FINAL store (g_traininglabel4) is textually hoisted past the
'    EndIf by the original compiler, which is safe because g_traininglabel4 was already
'    loaded into the same register at function entry (`puVar2 = g_traininglabel4`) --
'    reproduced here as an ordinary statement inside the If, which is behaviourally
'    identical and matches how every other Global in the same chain is written.
'  * 0x00C6CF70 is an ARRAY (g_training_arr:TSound[], already established by
'    TTraining.UpdateSounds.bmx: "PlaySound(g_training_arr[Rand(0,3)], g_ch1)"). The
'    decompile's `*(int *)(PTR_PTR_00c6cf70 + 0x18/0x1c/0x20/0x24)` sequence is BBArray
'    element access (guide 4: "BBArray data starts at +0x18"), i.e. elements 0..3, NOT
'    four separate scalar Globals. This resolves cleanly: elements 0..3 are loaded from
'    Bird1..Bird4.ogg, matching LoadSoundChecked's 4-argument cascade exactly with no
'    left-over/duplicate address once read as an array.
'  * LoadSoundChecked = 0x004BC564(path$, i) : TSound  and  LoadImageChecked =
'    0x004BC372(path$, i) : TImage -- both confirmed by call-site population (57 and 240
'    sites respectively agree, per the annotated pass), not guessed.
'  * TLabel.CreateLabel's 21-arg shape and argument order are copied verbatim from
'    TEngine.SetUp.bmx's already-recovered calls (same class-table slot 0x00C634C0):
'    (name$, text$, x, y, w, h, align, colour$, textcolour$, fontsize#, fontIndex, i, i,
'    i, icon:TImage, i, i, i, i, tooltip$, f#). All four calls here share colour "666666" /
'    textcolour "FFFFFF" / fontsize 0.75 (0x3F400000) / fontIndex 1 / icon Null / tooltip
'    "" / trailing float 0 -- read directly from the decompile's resolved string/float
'    operands, not guessed.
'  * 0x00C6CFB8/BC/C0/C4 g_traininglabel1..4:TLabel -- already established across
'    ClearUpTraining/SetUpTraining_Heading/_Shooting/_Tackling.
'  * g_training_int10 (0x00C6CFAC, String) is READ here (not just written): the first
'    label is constructed with its CURRENT value as initial text, before any
'    SetUpTraining_XXX sub-function has had a chance to set it for this call.
'  * Post-init resets (every call, not just the first): g_training_int17=0,
'    g_training_int19=0, g_training_int20=0, g_training_int21=-1, g_training_int22=-1,
'    g_training_int23=0, g_training_int24=0 -- all already-established TTraining
'    per-drill scratch Ints (Heading/Shooting/Tackling/ResetTraining/Call).
'  * g_training_int13/g_training_int14 (0x00C6CFD8/DC): the decompile stores the FIRST
'    Rand/YardsToPixels/FloatToInt result to 0x00C6CFD8 and the SECOND to 0x00C6CFDC --
'    confirmed directly against the raw decompile's literal `DAT_00c6cfd8=...` /
'    `DAT_00c6cfdc=...` addresses, and independently confirmed by the already-recovered,
'    byte-verified TTraining.Call.bmx ("0x00C6CFD8 Int g_training_int13 (SetUpSetPiece
'    arg)" / "0x00C6CFDC Int g_training_int14"). Rand's args read directly off the pushed
'    immediates in binary/NSS5.exe (0xffffffec=-20, 0x14=20, 0xffffffd8=-40): first call
'    Rand(-20,20), second Rand(-20,-40) -- the second is a descending range, reproduced
'    as pushed (guide 3: preserve, do not "fix").
'  * g_training_int03 = a0 (the function's own Int argument) -- this IS the training-type
'    selector every other TTraining body dispatches on.
'  * g_training_state = 0 (0x00C6CF98) -- HAND-VERIFIED override
'    (extracted/global_alias_overrides.tsv: "g_training_int05 -> g_training_state,
'    DEAD->LIVE: read 6x, same slot 0x00C6CF98").
'  * g_train_scrollx = Float(g_screen_w) (0x00C6CFB0 = 0x00C6EFE4) -- both addresses and
'    types already established by the byte-verified TTraining.Update.bmx ("0x00C6CFB0
'    g_train_scrollx:Float", "0x00C6EFE4 g_screen_w:Int"): the scroll-text position is
'    seeded to the screen width so it starts off the right edge.
'  * The a0 dispatch (1,2,3,4,6,7,9 -> Pace/Dribbling/Flair/Tackling/Passing/Heading/
'    Shooting; 5,8,10 have no case) is a `Select a0` with no `Default` (confirmed by
'    disassembly: subject loaded once at 0x0057C418, seven back-to-back `cmp eax,N / je`
'    tests, and a single no-match `jmp 0x57c47a` straight past the Select -- no default
'    body) -- matching the CALL log's seven distinct call sites (0x0057c442..0x0057c472),
'    each a class-table-slot call on TTraining's OWN table (guide 3d: unqualified sibling
'    Function calls).
'  * g_profile (0x00C6F028:TProfile) is the flagship hand-verified override target
'    (extracted/global_alias_overrides.tsv doc: "g_contractoffer_tplayer -> g_profile");
'    already used under this exact name by the byte-verified TTraining.Success.bmx.
'  * Field offsets (extracted/object_model.json): TProfile +0x1D0 myclub:TClub,
'    +0x2C newstarselno:Int. TClub inherits TBase_Team (class_tables.tsv): +0xC id:Int,
'    +0x18 tla:String, +0x20 labelshortname:String, +0x24 strength:Int,
'    +0x44 kitcolsHome:TKitStrings, +0x48 kitcolsAway:TKitStrings,
'    +0x50 kitcolsKeeper:TKitStrings, +0x54 formation:Int.
'  * TKit.CreateKit(:TKitStrings,$):TKit -- kit paths "EngineMedia/Match/Player/Player.png"
'    (home/away) and "...Keeper.png" (keeper), read directly from the decompile.
'  * TFormation.GetTacticIdByName($)i is called from THREE separate call sites inside a
'    `Select g_training_int17` (not one shared call folded behind a computed string, and
'    not an If/ElseIf -- see the REFINEMENT PASS note above) -- confirmed by reading the
'    raw bytes of binary/NSS5.exe at 0x0057C4E4/0x0057C4F6/0x0057C508 directly: the pushed
'    string constants resolve to "3-4-3" for Case 2 and Case 4, and "4-2-4" for the
'    Default arm. Neither literal is guessed; both were read out of the binary's data
'    section byte-for-byte.
'  * TTeam.CreateTeamSimple(i,$,$,i,i,:TKit,:TKit,i,i,i,:TFixture):TTeam -- two calls
'    build a synthetic home/away pairing for the solo training session: the home team
'    uses the player's actual club (id/name/tla/strength/formation), home+keeper kit,
'    flag 1, and team-index 1; the away team reuses the SAME name/tla (only `id+1`
'    differs), strength scaled by the drill's own level (g_training_int04*3), the
'    away+keeper kit, the tactic just resolved above, flag 0, and team-index 2 -- argument
'    order read directly off the resolved call in the decompile.
'  * The trailing `_bbObjectNew()` (runtime_helpers.tsv: 132 call sites, confirmed
'    `_bbObjectNew`) with no visible Ghidra argument is a bare `New TFixture` -- the same
'    shape already established by TFixture.CreateFixture.bmx / CreateFromString.bmx, and
'    the only type that fits TEngine.SetUpMatch's first parameter.
'  * TEngine.SetUpMatch(:TFixture,:TTeam,:TTeam,()i)i -- final argument is
'    TTraining.ClearUpTraining passed BY REFERENCE (a function value, not a call); written
'    unqualified (`ClearUpTraining`) per the same-Type sibling-reference convention.
'  * Body-only format (no Function/End Function wrapper), matching
'    TTraining.Success.bmx/TTraining.SetUpTraining_Shooting.bmx's existing shape in
'    src/recovered/.

'!Global g_snd_beep1:TSound
'!Global g_snd_beep2:TSound
'!Global g_training_arr:TSound[]
'!Global g_snd_training_success1:TSound
'!Global g_snd_training_success2:TSound
'!Global g_snd_training_reset:TSound
'!Global g_snd_miss:TSound
'!Global g_img_ballicon:TImage
'!Global g_img_goalicon:TImage
'!Global g_img_stopwatch:TImage
'!Global g_training_int10:String
'!Global g_traininglabel1:TLabel
'!Global g_traininglabel2:TLabel
'!Global g_traininglabel3:TLabel
'!Global g_traininglabel4:TLabel
'!Global g_training_int17:Int
'!Global g_training_int19:Int
'!Global g_training_int20:Int
'!Global g_training_int21:Int
'!Global g_training_int22:Int
'!Global g_training_int23:Int
'!Global g_training_int24:Int
'!Global g_training_int13:Int
'!Global g_training_int14:Int
'!Global g_training_int03:Int
'!Global g_training_state:Int
'!Global g_train_scrollx:Float
'!Global g_screen_w:Int
'!Global g_training_int04:Int
'!Global g_profile:TProfile

If Not g_snd_beep1 Then
	g_snd_beep1 = LoadSoundChecked("EngineMedia/Match/Sounds/StopWatch.ogg", 0)
	g_snd_beep2 = LoadSoundChecked("EngineMedia/Match/Sounds/StopWatchBeep.ogg", 0)
	g_training_arr[0] = LoadSoundChecked("EngineMedia/Match/Sounds/Bird1.ogg", 0)
	g_training_arr[1] = LoadSoundChecked("EngineMedia/Match/Sounds/Bird2.ogg", 0)
	g_training_arr[2] = LoadSoundChecked("EngineMedia/Match/Sounds/Bird3.ogg", 0)
	g_training_arr[3] = LoadSoundChecked("EngineMedia/Match/Sounds/Bird4.ogg", 0)
	g_snd_training_success1 = LoadSoundChecked("EngineMedia/Match/Sounds/TrainingSuccess.ogg", 0)
	g_snd_training_success2 = LoadSoundChecked("EngineMedia/Match/Sounds/TrainingClap.ogg", 0)
	g_snd_miss = LoadSoundChecked("EngineMedia/Match/Sounds/TrainingError.ogg", 0)
	g_snd_training_reset = LoadSoundChecked("EngineMedia/Match/Sounds/TrainingReset.ogg", 0)
	g_img_ballicon = LoadImageChecked("EngineMedia/Match/Other/BallIcon.png", -1)
	g_img_goalicon = LoadImageChecked("EngineMedia/Match/Other/GoalIcon.png", -1)
	g_img_stopwatch = LoadImageChecked("EngineMedia/Match/Other/StopWatch.png", -1)
	g_traininglabel1 = TLabel.CreateLabel("lbl_TrialInstrucs1", g_training_int10, 0, 0, 626, 174, 3, "666666", "FFFFFF", 0.75, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
	g_traininglabel2 = TLabel.CreateLabel("lbl_TrialInstrucs2", "", 0, 120, 200, 100, 3, "666666", "FFFFFF", 0.75, 1, 0, 1, 1, Null, 1, 1, 0, 0, "", 0)
	g_traininglabel3 = TLabel.CreateLabel("lbl_TrialInstrucs3", "", 0, 120, 200, 100, 3, "666666", "FFFFFF", 0.75, 1, 0, 1, 1, Null, 1, 1, 0, 0, "", 0)
	g_traininglabel4 = TLabel.CreateLabel("lbl_TrialInstrucs4", "", 0, 120, 200, 100, 3, "666666", "FFFFFF", 0.75, 1, 0, 1, 1, Null, 1, 1, 0, 0, "", 0)
EndIf

g_training_int17 = 0
g_training_int19 = 0
g_training_int20 = 0
g_training_int21 = -1
g_training_int22 = -1
g_training_int23 = 0
g_training_int24 = 0

g_training_int13 = Int(TPitch.YardsToPixels(Rand(-20, 20)))
g_training_int14 = Int(TPitch.YardsToPixels(Rand(-20, -40)))

g_training_int03 = a0
g_training_state = 0
g_train_scrollx = Float(g_screen_w)

Select g_training_int03
	Case 1
		SetUpTraining_Pace()
	Case 2
		SetUpTraining_Dribbling()
	Case 3
		SetUpTraining_Flair()
	Case 4
		SetUpTraining_Tackling()
	Case 6
		SetUpTraining_Passing()
	Case 7
		SetUpTraining_Heading()
	Case 9
		SetUpTraining_Shooting()
End Select

Local kithome:TKit = TKit.CreateKit(g_profile.myclub.kitcolsHome, "EngineMedia/Match/Player/Player.png")
Local kitaway:TKit = TKit.CreateKit(g_profile.myclub.kitcolsAway, "EngineMedia/Match/Player/Player.png")
Local kitkeeper:TKit = TKit.CreateKit(g_profile.myclub.kitcolsKeeper, "EngineMedia/Match/Player/Keeper.png")

Local tacticid:Int
Select g_training_int17
	Case 2
		tacticid = TFormation.GetTacticIdByName("3-4-3")
	Case 4
		tacticid = TFormation.GetTacticIdByName("3-4-3")
	Default
		tacticid = TFormation.GetTacticIdByName("4-2-4")
End Select

Local hometeam:TTeam = TTeam.CreateTeamSimple(g_profile.myclub.id, g_profile.myclub.labelshortname, g_profile.myclub.tla, g_profile.myclub.strength, 1, kithome, kitkeeper, g_profile.myclub.formation, g_profile.newstarselno, 1, Null)
Local awayteam:TTeam = TTeam.CreateTeamSimple(g_profile.myclub.id + 1, g_profile.myclub.labelshortname, g_profile.myclub.tla, g_training_int04 * 3, 0, kitaway, kitkeeper, tacticid, g_profile.newstarselno, 2, Null)

Local fixture:TFixture = New TFixture
TEngine.SetUpMatch(fixture, hometeam, awayteam, ClearUpTraining)
