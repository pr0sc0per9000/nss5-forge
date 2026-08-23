' TScreen_GameMenu.UpdateNavPanel
' VA 0x0053AC42   1361 bytes   vtable slot 0x3c   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe
' Source: extracted/decomp/TScreen_GameMenu.UpdateNavPanel@0053ac42.c, cross-checked
' statement-by-statement against harness.disasm_original(0x0053ac42, after=1000) (the raw
' x86 -- the decompilation merges several call argument lists here, see below). Siblings
' read closely: TScreen_GameMenu.UpdateTitlePanel.bmx, TScreen_GameMenu.UpdateMatchRefresh.bmx
' and TScreen_GameMenu.CreateScreen.bmx (same Type; CreateScreen's header is what resolves
' 0x00C66780/0x00C66784/0x00C66794 to g_lbl_year/g_lbl_week/g_lbl_nextopp2), plus
' TScreen_GameMenu.ButtonPlay.bmx (src/recovered_pending, same Type, same g_profile address).
'
' GLOBALS (name/type per scripts/explain_global.py address solver):
'   0x00C66780 g_lbl_year:TLabel      -- STRONG (explain_global, 2 bodies), construction
'                                         site is CreateScreen; slot 0x64 = TGadget.SetText.
'   0x00C66784 g_lbl_week:TLabel      -- same tier/source as g_lbl_year.
'   0x00C66794 g_lbl_nextopp2:TLabel  -- same tier/source; slot 0x64 SetText, 0x6c SetColour.
'   0x00C6F028 g_profile:TProfile     -- explain_global's raw-count CERTAIN pick for this
'                                         address is g_contractoffer_tplayer (20 bodies); STRONG
'                                         g_profile has 142 bodies/102-104 agreement. Overridden
'                                         to g_profile here for the same reason ButtonPlay.bmx
'                                         gives: every OTHER already-verified TScreen_GameMenu
'                                         body (UpdateTitlePanel, UpdateMatchRefresh, ButtonPlay,
'                                         ButtonQuit, ButtonCompetitions) declares this exact
'                                         address g_profile:TProfile -- within-Type consistency
'                                         wins over the raw unanimity count.
'
' FIELD / SLOT RESOLUTION (object_model.json, cross-checked against globals_classtable_slots.tsv
' and, where possible, against the field maps already written into sibling headers):
'   TProfile      +0x10 date:TMyDate   +0x16C injury   +0x198 banclub   +0x19C bancontinent
'                 +0x1A0 baninternational
'                 slot 0x58 GetNextFixture(i):TFixture, 0x5C GetNextOpponent(*i,*i):TBase_Team
'   TMyDate       +0x08 sdate ; slot 0x30 Create(i,i,i):TMyDate (Function), 0x54 GetYear()i,
'                 0x5C GetString($)$
'   TFixture      +0x40 compid  (matches TFixture.GetStringArrayForTeamId.bmx's own field map:
'                 "...score2+56 compid+64")
'   TCompetition  +0x18 locale  +0x1C level  +0x50 compstatus  (locale/level match
'                 TScreen_GameMenu.ButtonPlay.bmx's own field map exactly); slot 0xF8 =
'                 IsCupFinal()i ; Function slot 0x4C = SelectById(i):TCompetition, resolved via
'                 globals_classtable_slots.tsv's 0x00C6160C row.
'   TBase_Team    +0x1C labelname:String
'   0x00C6632C = TMyDate+0x30 Create(i,i,i):TMyDate (globals_classtable_slots.tsv).
'   E8 targets (runtime_helpers.tsv): 0x004A7410 _brl_retro_Lower (Lower), 0x004A7AC0
'     _bbStringFromInt (String(int)), 0x004A7C20 _bbStringConcat (`+`), 0x004A7C90
'     _bbStringSlice (`[a..b]`). 0x004C5549 is the recovered module Function GetText.
'   String literals read with harness.read_string(): 0x00C84FE8 "YYYY", 0x00C85010 "WWWW",
'     0x00C70ED4 "fixture_Bye", 0x00C73A70 "888888", 0x00C5D680 "FFFFFF", 0x00C70F78
'     "sla_Home", 0x00C70F94 "sla_Away", 0x00C70F18 ") ", 0x00C70F28 "(", 0x00C70EF8 ")",
'     0x00C70F08 " (", 0x00C70DD0 " - ", 0x00C85BC0 "Banned", 0x00C85BD8 "Injury",
'     0x00C725EC "FF0000", 0x00C85BF0 "tla_ToBeConfirmed"; 0x00C5D284 is the zero-length
'     BBString "" (read_string returns None for it -- length 0 fails its own `0 < ln` guard,
'     matching CreateScreen.bmx's note on the same address).
'
' GHIDRA ARGUMENT-LIST MERGES (all confirmed against harness.disasm_original -- add esp after
' each call gives the true arity):
'   * Every `label.SetText(...)` call shows extra leading args in the decompilation; GetString/
'     GetText's OWN arity is 1 (self+1 for GetString, just 1 for GetText -- `add esp,4`/`add
'     esp,8` after each proves it), and the "" ,-1,-1 tail belongs to the FOLLOWING SetText,
'     exactly the TProfile.StartCareer.bmx GetText-merge pattern.
'   * The Home/Away opponent-name phrase and the Banned/Injury suffix are each a flat
'     left-to-right `+` chain (tail literals get pushed in reverse order ahead of the first
'     concat, then each concat consumes one more of them -- same shape as the `"(" +
'     GetText("sla_Home") + ") " + opp.labelname` block, verified against the raw pushes).
'   * The `" - " + Lower(GetText(...))[..3] + " (" + String(n) + ")"` suffix is a separate
'     parenthesised group appended to the running text with a SINGLE trailing concat (own
'     four gets built first, accumulator joins last) -- the exact shape documented in
'     TFixture.GetStringArrayForTeamId.bmx's note 2 (`arr[0] + (" d" + d.GetDay())`).
'   * `Not fx Or (checkdate <> Null And checkdate.GetYear() > g_profile.date.GetYear())` is the
'     same double-negation idiom (setne/movzx/cmp/sete/movzx/cmp) TProfile.GetNextOpponent.bmx
'     documents for `If Not natfix Or (...)` -- Not of the first Or-operand gets materialised
'     because it feeds a compound boolean, not because the source says anything but `Not fx`.
'   * `g_profile.baninternational And isIntl`, `g_profile.bancontinent And comp.locale = 1`,
'     `g_profile.banclub And comp.locale = 0` all feed the raw Int field straight into the
'     `And` with no `<> 0` materialisation (no setne/movzx on the LHS, just cmp/je on the bare
'     field) -- the TWeather.UpdateRain.bmx-documented `If g_rainmode And ...` byte saving.
'
' STRUCTURE
'   * `g_lbl_nextopp2.SetText(GetText("fixture_Bye"),...)` and `SetColour("888888","FFFFFF")`
'     run unconditionally up front -- overwritten below only when there IS a next fixture.
'   * The "(Home) Name" phrase is built UNCONDITIONALLY first and then fully rebuilt as
'     "(Away) Name" when `isHome = 0` -- the first computation's result is simply discarded.
'     Original inefficiency, kept as-is (preserve-by-default).
'   * BUG (original), preserved: `TCompetition.SelectById(fx.compid)` dereferences `fx` with
'     no Null guard, on a line whose own next statement tests `fx <> Null` and whose tail
'     tests `Not fx`. Ground truth, VA 0x0053AD21:
'         mov  eax,[ebp-0xc]        ; fx, stored at 0x0053ACF7 from GetNextFixture
'         push dword [eax+0x40]     ; fx.compid -- no cmp against 0x5c9c80 in between
'         call dword [0xc6160c]     ; = 0x0050A60F TCompetition.SelectById
'     `fx` IS Null the first time this function runs in a career, and that is reachable
'     rather than theoretical: TScreen_ContractOffer.ButtonAccept (0x00554297) calls
'     SignForNewClub first and the accept callback second, so SignForNewClub's
'     `TScreen_GameMenu.UpdateNavPanel()` at 0x005734B0 runs before TProfile.StartCareer,
'     and StartCareer is the only route into TCompetition.SetUpCompetitionsAll, which is
'     the only producer of fixture lists. Retail swallows it: `Null` is `&bbNullObject`
'     = 0x005C9C80, so `[eax+0x40]` reads 0x005C9CC0 in .data (value 0x004A9C80), no
'     competition carries that id, and the `If Not fx` branch below writes
'     "tla_ToBeConfirmed" as intended. A `-d` build throws
'     "Attempt to access field or method of Null object" here instead.
'     DO NOT add a Null guard: the original has none and adding one changes the bytes.
'   * `If comp <> Null` re-guards a value already proven non-Null by the big outer `And` chain
'     a few lines above -- a genuine redundant check in the original (decompilation confirms:
'     `if (piVar6 != &DAT_005c9c80)` reappears verbatim at line 121 of the .c).
'   * The trailing ToBeConfirmed check runs unconditionally (outside the big `fx<>Null And
'     opp<>Null And comp<>Null` guard), using its own freshly-built `checkdate`.
'
' UNCERTAINTIES
'   * Refinement pass (2026-08-16): status/score/TScreen_GameMenu.UpdateNavPanel.txt reports
'     76.9% via the shared-build positional scorer, first difference at byte 11 inside a
'     `MOV EBX,[global]` operand -- that is exactly the relocation/address-desync artefact
'     scripts/score_bodies.py's own docstring warns about, not a body defect. Re-checked with
'     `python scripts/localise_diff.py TScreen_GameMenu.UpdateNavPanel
'     src/recovered_unverified/TScreen_GameMenu.UpdateNavPanel.bmx`, which builds a private
'     probe via the real oracle (harness.try_method) and aligns/masks relocations before
'     comparing: result is gap_count=0, sub_count=0, first_divergence=null, oracle_status
'     MATCH (mode=reloc), verdict "CLEAN -- byte-identical modulo the oracle's masks". This
'     body is correct as written; do not rewrite it chasing the stale 76.9% figure.
'   * The bare-Int-into-And/Or spelling (no `<> 0`) for the three ban-flag checks and for
'     `Not fx Or (...)` is inferred from the cited sibling precedents, not proven for this
'     exact function.
'   * `[..3]` vs `[0..3]` for the slice: both spellings are used elsewhere in the corpus
'     (TDate.GetStringMonth.bmx vs TDate.GetStringWeekday.bmx) and should be byte-identical;
'     `[..3]` chosen to match the closer analog (a literal end bound, not a variable one).
'   * Local names (fx, isHome, isIntl, opp, comp, txt, checkdate) are this pass's invention --
'     no debug info exists for them.

'!Global g_lbl_year:TLabel
'!Global g_lbl_week:TLabel
'!Global g_lbl_nextopp2:TLabel
'!Global g_profile:TProfile
' CASE DIRECTION CORRECTED 2026-08-22: 4 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
g_lbl_year.SetText(g_profile.date.GetString("YYYY"), "", -1, -1)
g_lbl_week.SetText(g_profile.date.GetString("WWWW"), "", -1, -1)
g_lbl_nextopp2.SetText(GetText("fixture_Bye"), "", -1, -1)
g_lbl_nextopp2.SetColour("888888", "FFFFFF")
Local fx:TFixture = g_profile.GetNextFixture(0)
Local isHome:Int = 0
Local isIntl:Int = 0
Local opp:TBase_Team = g_profile.GetNextOpponent(Varptr isHome, Varptr isIntl)
' BUG (original), preserved -- see the STRUCTURE note above. `fx` is Null the first time a
' career reaches here and this reads through it unguarded, exactly as 0x0053AD21 does.
Local comp:TCompetition = TCompetition.SelectById(fx.compid)
If fx <> Null And opp <> Null And comp <> Null
	Local txt:String = "(" + GetText("sla_Home") + ") " + opp.labelname
	If isHome = 0
		txt = "(" + GetText("sla_Away") + ") " + opp.labelname
	EndIf
	If g_profile.baninternational And isIntl
		txt = txt + (" - " + GetText("Banned").ToUpper()[..3] + " (" + String(g_profile.baninternational) + ")")
	Else
		If g_profile.bancontinent And comp.locale = 1
			txt = txt + (" - " + GetText("Banned").ToUpper()[..3] + " (" + String(g_profile.bancontinent) + ")")
		ElseIf g_profile.banclub And comp.locale = 0
			txt = txt + (" - " + GetText("Banned").ToUpper()[..3] + " (" + String(g_profile.banclub) + ")")
			g_lbl_nextopp2.SetColour("FF0000", "FFFFFF")
		ElseIf g_profile.injury
			txt = txt + (" - " + GetText("Injury").ToUpper()[..3] + " (" + String(g_profile.injury) + ")")
		EndIf
	EndIf
	g_lbl_nextopp2.SetText(txt, "", -1, -1)
	If comp <> Null
		If comp.IsCupFinal()
			g_lbl_nextopp2.SetText(opp.labelname, "", -1, -1)
		ElseIf comp.level = 1 And (comp.locale = 2 Or comp.compstatus = 1)
			g_lbl_nextopp2.SetText(opp.labelname, "", -1, -1)
		EndIf
	EndIf
EndIf
Local checkdate:TMyDate = Null
If fx <> Null Then checkdate = TMyDate.Create(fx.sdate, 1, 1)
If Not fx Or (checkdate <> Null And checkdate.GetYear() > g_profile.date.GetYear())
	g_lbl_nextopp2.SetText(GetText("tla_ToBeConfirmed"), "", -1, -1)
EndIf
Return 0
