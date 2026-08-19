' TScreen_ReportBoss.SetUpScreen
' VA 0x00561DFF   1492 bytes   KIND=Function (static), SIG ()i, class-table slot 0x34
' byte-identical vs NSS5.exe
' NOT YET BYTE-VERIFIED. Reconstructed from extracted/decomp/TScreen_ReportBoss.SetUpScreen@00561dff.c
' and cross-checked against a fresh raw disassembly pulled straight from the read-only Ghidra
' project (scripts/ghidra_scripts-style -postScript listing of 0x00561dff for 1492 bytes; see
' SHAPE NOTES below for why the decompiled .c text alone is not trustworthy here). Staged in
' recovered_pending pending an oracle pass; not yet claimed byte-identical.
'
' REFINEMENT PASS (oracle showed 993/1490, 66.6%, first diff at byte 9): the byte oracle was
' compared instruction-by-instruction against BOTH `scripts/disasm.py 0x00561dff` (the real
' NSS5.exe) and this body's own compiled form in src/assembled/nss5_assembled.exe (found via
' scripts/bytematch.py's find_method, then disassembled read-only -- no assemble.py run). With
' every absolute address normalised away, the two instruction streams matched EXACTLY from byte
' 0 through byte 605 (the whole opening: SetActive, SetIcon, LoadImageChecked+refcount dance,
' the drugs=99/Else LogLine split, the six UpdateRelationship punches, the Match-Report SetText,
' the coachreport If/Else concat, the two "" resets, the GotSponsor guard). Two real, fixable
' divergences were found past that point and are fixed below; a third, smaller one is noted but
' NOT fixed because no safe source-level cause could be confirmed:
'   1. byte 605/609 (coachrep_fame decay guard): original is `cmp [.+0x70],0 / jg SKIP` (execute
'      the decay block when the field is <= 0), not `cmp .,1 / jge SKIP` (< 1). Both are true for
'      integers, but only "<= 0" reproduces the original's actual comparison immediate and jcc
'      opcode. Fixed: `If g_profile.coachrep_fame <= 0`.
'   2. bytes 726/846/966/1086/1206 (all five sign picks): original's jcc is `jl` and the STRING
'      IT JUMPS TO IS " " (i.e. the jump-target is the NEGATIVE case), with " +" as the
'      fallthrough -- the reverse of what a literal `If x < 0 Then " " Else " +"` compiles to
'      (that compiles to `jge` skipping straight to the ELSE, confirmed by disassembling this
'      body's own prior compiled form: it had `jge`, not `jl`). Read out fully: `jl NEG_LABEL;
'      <fallthrough, x>=0> sign=" +"; jmp CONT; NEG_LABEL: sign=" "; CONT:` is exactly what `If x
'      >= 0 Then sign = " +" Else sign = " "` compiles to (test the WRITTEN condition, skip-if-
'      false to the Else). Fixed all five: boss/team/fans/sponsors/fame now test `>= 0` with the
'      branches swapped. Net string/behaviour is identical either way (same sign for every value
'      of x) -- this is purely a source-phrasing fix to match the byte-observable comparison.
'   3. byte ~1377, immediately after the fifth `coachrep_fame = 0` reset and before the
'      helppages/Tutorial check: the original has one more instruction, `EB 00` (`jmp $+2`, a
'      no-op unconditional jump to the very next byte) that this body was not emitting -- the
'      exact 2 bytes of this body's `ours 1490 vs original 1492` length delta, and the reason
'      every byte from there to EOF was reported as a mismatch (a pure position shift, not a
'      logic difference -- re-confirmed instruction-by-instruction with normalised operands: the
'      whole tail from the sign/label blocks onward is otherwise IDENTICAL in shape). This kind
'      of dead `jmp $+2` is a real, attested BlitzMax codegen artifact elsewhere in the corpus
'      (e.g. TEngine.SetUpWeatherConditions.bmx mid-block after a Local's initialiser, and
'      TNation.Compare.bmx/TBase_Team.Compare.bmx emit one after every Select Case including the
'      last) but a scan of ~570 occurrences across the binary did not turn up a single-source-
'      shape rule specific enough to justify inserting a construct here that isn't independently
'      evidenced for this block (an outer `If <>0 ... EndIf` with no real Else, unlike the two
'      attested cases above). Tried, and left in as a best-effort per rule 4: an empty `Else`
'      before this block's `EndIf` (harmless either way -- doesn't change behaviour -- and is the
'      only source shape that would mechanically explain a redundant jump-to-here from a
'      skip-the-Else close). If the next oracle pass shows this didn't move the tail back into
'      alignment, drop the empty Else again; it was a guess, not a confirmed fix, unlike 1 and 2.
'
' Sets the "reportboss" screen active, loads its background, and -- IF the profile has a
' pending boss report (bossreport.Length<>0) -- writes the match-report panel title, the boss
' report text label (merged with any pending coach report), five "category +N%" coach-rating
' labels (boss/team/fans/sponsors/fame), and a hidden debug cheat: setting profile.drugs to 99
' logs "Drugs lose friends" and tanks six relationships instead of showing the normal report.
' Finally (outside that guard) it shows the one-time tutorial help box for this screen.
'
' GLOBALS -- addresses are fact; names are the established corpus choices, not invented here.
' python scripts/explain_global.py <addr> resolves 0 names for every TScreen_ReportBoss slot
' below (0x00C68ADC..0x00C68B04) -- the solver has not ingested this Type's construction
' sites yet -- so the names come from the STRONGEST available sibling instead: this Type's own
' byte-verified src/recovered/TScreen_ReportBoss.CreateScreen.bmx, which builds every one of
' these objects and pragma-declares them individually with these exact addresses in its own
' header. 0x00C68AE0 is additionally corroborated by src/recovered/TScreen_ReportBoss.Draw.bmx,
' which already reads it as g_reportboss_img:TImage -- this function is that Global's only
' writer, so writing it here is what revives Draw's dead dereference.
'   0x00C68ADC g_reportboss_screen:TScreen      0x00C68AE0 g_reportboss_img:TImage
'   0x00C68AE8 g_reportboss_pan_report:TPanel   0x00C68AEC g_reportboss_lbl_boss:TLabel
'   0x00C68AF0 g_reportboss_lbl_coachboss:TLabel   0x00C68AF4 g_reportboss_lbl_coachteam:TLabel
'   0x00C68AF8 g_reportboss_lbl_coachfans:TLabel   0x00C68AFC g_reportboss_lbl_coachsponsors:TLabel
'   0x00C68B00 g_reportboss_lbl_coachfame:TLabel   0x00C68B04 g_reportboss_btn_play:TButton
' 0x00C6F274 g_img_play:TImage -- explain_global.py STRONG, also declared by CreateScreen.bmx.
' 0x00C6F028 g_profile:TProfile -- explain_global.py STRONG, 142 declaring bodies (102/104
'   agree), including the note "g_contractoffer_tplayer is now g_profile,
'   g_profile is what 6 other files already call 0x00C6F028". The sibling this function's Else
'   branch is called FROM, src/recovered/TScreen_ReportPhysio.SetUpScreen.bmx, already reads
'   this exact slot as g_profile and already reads its .bossreport / .physioreport fields.
'
' CALL TARGETS (class_tables.tsv classtable_va + vtable_map.tsv slot, cross-checked against
' extracted/decomp_annotated/TScreen_ReportBoss.SetUpScreen@00561dff.c's SYM/legend table):
'   0x00C61C88 = TScreen+0x5C SetActive($,$):TScreen      0x00C61CE0 = TScreen+0xB4 Tutorial()i
'   0x00C638BC = THelpBox+0x30 Create(:TGadget,i,i,i,i,$,i,i):THelpBox
'   TButton/TGadget+0x90 SetIcon(:TImage)i   TGadget+0x64 SetText($,$,i,i)i (TPanel/TLabel both
'   inherit it unmodified)   TProfile+0xC0 UpdateRelationship(i,i)i   TProfile+0x120 GotSponsor()i
'   TList+0x44 AddLast(:Object)i (g_reportboss_screen.lHelp, TScreen field +0x1C, object_model.json)
'   0x004BC372 LoadImageChecked($,i):TImage   0x00505B91 LogLine($)i   0x004C5549 GetText($)$
'   0x004A7AC0 _bbStringFromInt   0x004A7C20 _bbStringConcat   0x004A7410 _brl_retro_Lower
'   0x004A6A30 _bbStringCompare   0x00505F90 ClampFloat(*f,f,f)i   0x005B9690 _bbFloatToInt
'
' Fields (object_model.json): TProfile bossreport=+0x54($) coachreport=+0x5C($)
'   coachrep_boss=+0x60(i) coachrep_team=+0x64(i) coachrep_fans=+0x68(i) coachrep_sponsors=+0x6C(i)
'   coachrep_fame=+0x70(i) drugs=+0x188(i) myclub=+0x1D0(:TClub) helppages=+0x1C8([]i).
'   TBase_Team (TClub's super) strength=+0x24(i). TScreen lHelp=+0x1C(:TList).
'
' SHAPE NOTES
'   * THE DECOMPILED .c TEXT MISATTRIBUTES ARGUMENTS ACROSS ADJACENT CALLS for this whole
'     function -- confirmed by re-disassembling 0x00561DFF..0x005623D2 directly (Ghidra's
'     high-level printer accumulates every pushed-but-not-yet-consumed stack slot into
'     whichever CALL node it is printing, which is NOT the same as which call actually pops
'     those bytes). Two concrete examples that would have been silently wrong if trusted
'     as printed: (1) `FUN_004c5549(&PTR_PTR_00c8d7c8,&PTR_PTR_00c5d284,0xffffffff,0xffffffff)`
'     prints as a 4-arg GetText call, but `add esp,0x4` after it proves only ONE argument is
'     really consumed ("Match Report") -- the trailing "",-1,-1 are the SetText call's OWN
'     literal args, pushed early because they need no computation. (2) the boss/team/fans/
'     sponsors/fame blocks print `FUN_004a7ac0(coachrep_boss,"%","",...)` (StringFromInt with
'     4 args) when it is really StringFromInt(coachrep_boss) alone, ADD ESP,0x4 straight after.
'     Resolved by walking the real ESP-relative PUSH/CALL/ADD-ESP sequence by hand; every
'     helper's true arity below matches the "(N sites agree)" counts already recorded in
'     extracted/decomp_annotated/TScreen_ReportBoss.SetUpScreen@00561dff.c.stats.json.
'   * The five coach-rating labels are built as `Lower(GetText(cat)) + sign + String(delta) +
'     "%"` (confirmed by the 3 chained _bbStringConcat calls' actual operand pairs from the
'     stack trace: Concat(lower,sign) then Concat(that,numstr) then Concat(that,"%")) -- e.g.
'     coachrep_boss=12 renders "boss +12%", coachrep_boss=-5 renders "boss -5%" (the leading
'     "-" comes from String(-5) itself; `sign` is only ever " " or " +").
'   * `PUSH 0xc8d780; CALL LogLine` prints with NO argument at all in the decompiled text (same
'     misattribution bug) -- read directly out of the exe's data section (BBString layout:
'     length at object+8, UTF-16 chars at object+0xC): the string is "Drugs lose friends", a
'     hidden debug message for the `profile.drugs = 99` cheat branch.
'   * The `profile.drugs = 99` branch is a genuine developer cheat/debug path, not a normal
'     report: it skips the whole boss/coach-report display and instead punches six
'     relationships down via UpdateRelationship (boss -50, team -30, fans -30, friends -10,
'     girlfriend -10, sponsors -50 -- confirmed against src/recovered/TProfile.
'     UpdateRelationship.bmx's own Select-Case index meaning) and resets drugs to 0.
'   * The fame relationship additionally decays passively whenever coachrep_fame <= 0 (i.e. no
'     fame-changing event queued this report -- confirmed against the real `cmp .,0 / jg SKIP`,
'     not a `< 1` reading): `local_8 = (55 - myclub.strength/2) * 0.1`,
'     clamped to [1.0, 5.0], then `UpdateRelationship(7, Int(-local_8))` -- always a reduction,
'     preserved exactly including the always-negative sign (ORIGINAL BEHAVIOUR, not a bug in
'     this reconstruction: a bigger club's strength shrinks the penalty, it never removes it).
'   * `g_profile.bossreport.Length <> 0` (a direct String-header field read) gates the WHOLE
'     report block; `g_profile.coachreport = ""` (a real _bbStringCompare call, not a length
'     check) decides whether the boss-report label shows bossreport alone or
'     "bossreport + ' ' + coachreport" -- the two guards use genuinely different mechanisms in
'     the original and are reproduced as such, not unified into one style.
'   * `g_profile.coachrep_sponsors` is force-zeroed when `GotSponsor()=0` BEFORE the sponsors
'     label reads it a few lines later, so a player with no sponsor always sees "sponsors +0%".
'     Preserved as-is (law 3).
'   * helppages index 22 = TProfile+0x1C8 (BBArray data at object+0x18) + 22*4 = object+0x70.
'   * The closing THelpBox anchors on g_reportboss_lbl_coachboss (not lbl_boss), matching the
'     0x00C68AF0 operand read directly out of the call-site disassembly.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_profile:TProfile
'!Global g_reportboss_screen:TScreen
'!Global g_reportboss_img:TImage
'!Global g_reportboss_pan_report:TPanel
'!Global g_reportboss_lbl_boss:TLabel
'!Global g_reportboss_lbl_coachboss:TLabel
'!Global g_reportboss_lbl_coachteam:TLabel
'!Global g_reportboss_lbl_coachfans:TLabel
'!Global g_reportboss_lbl_coachsponsors:TLabel
'!Global g_reportboss_lbl_coachfame:TLabel
'!Global g_reportboss_btn_play:TButton
'!Global g_img_play:TImage
TScreen.SetActive("reportboss", "btn_play")
g_reportboss_btn_play.SetIcon(g_img_play)
g_reportboss_img = LoadImageChecked("GameMedia\Images\Backgrounds\report_boss.png", -1)
If g_profile.bossreport.Length <> 0
	If g_profile.drugs = 99
		LogLine("Drugs lose friends")
		g_profile.drugs = 0
		g_profile.UpdateRelationship(1, -50)
		g_profile.UpdateRelationship(2, -30)
		g_profile.UpdateRelationship(3, -30)
		g_profile.UpdateRelationship(4, -10)
		g_profile.UpdateRelationship(5, -10)
		g_profile.UpdateRelationship(6, -50)
	Else
		LogLine("Drugs:" + String(g_profile.drugs))
	EndIf
	g_reportboss_pan_report.SetText(GetText("Match Report"), "", -1, -1)
	If g_profile.coachreport = ""
		g_reportboss_lbl_boss.SetText(g_profile.bossreport, "", -1, -1)
	Else
		g_reportboss_lbl_boss.SetText(g_profile.bossreport + " " + g_profile.coachreport, "", -1, -1)
	EndIf
	g_profile.bossreport = ""
	g_profile.coachreport = ""
	If g_profile.GotSponsor() = 0 Then g_profile.coachrep_sponsors = 0
	If g_profile.coachrep_fame <= 0
		Local local_8:Float = (55 - g_profile.myclub.strength / 2) * 0.1
		ClampFloat(Varptr local_8, 1.0, 5.0)
		g_profile.UpdateRelationship(7, Int(-local_8))
	EndIf
	Local sign:String
	If g_profile.coachrep_boss >= 0 Then sign = " +" Else sign = " "
	g_reportboss_lbl_coachboss.SetText(Lower(GetText("Boss")) + sign + String(g_profile.coachrep_boss) + "%", "", -1, -1)
	If g_profile.coachrep_team >= 0 Then sign = " +" Else sign = " "
	g_reportboss_lbl_coachteam.SetText(Lower(GetText("Team")) + sign + String(g_profile.coachrep_team) + "%", "", -1, -1)
	If g_profile.coachrep_fans >= 0 Then sign = " +" Else sign = " "
	g_reportboss_lbl_coachfans.SetText(Lower(GetText("Fans")) + sign + String(g_profile.coachrep_fans) + "%", "", -1, -1)
	If g_profile.coachrep_sponsors >= 0 Then sign = " +" Else sign = " "
	g_reportboss_lbl_coachsponsors.SetText(Lower(GetText("Sponsors")) + sign + String(g_profile.coachrep_sponsors) + "%", "", -1, -1)
	If g_profile.coachrep_fame >= 0 Then sign = " +" Else sign = " "
	g_reportboss_lbl_coachfame.SetText(Lower(GetText("Fame")) + sign + String(g_profile.coachrep_fame) + "%", "", -1, -1)
	g_profile.coachrep_boss = 0
	g_profile.coachrep_team = 0
	g_profile.coachrep_fans = 0
	g_profile.coachrep_sponsors = 0
	g_profile.coachrep_fame = 0
Else
EndIf
If g_profile.helppages[22] = 0
	TScreen.Tutorial()
	g_profile.helppages[22] = 1
EndIf
g_reportboss_screen.lHelp.AddLast(THelpBox.Create(g_reportboss_lbl_coachboss, 0, 0, 0, 0, GetText("CHELP_REPORTRELATIONSHIPS"), 2, 2))
