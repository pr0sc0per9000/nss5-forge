' TPitch.SetUpFans
' VA 0x004E6014   1533 bytes   KIND=Function (static), SIG (:TTeam,:TTeam,i)i, class-table slot 0x3C
' byte-identical vs NSS5.exe (1533/1533).
' Reconstructed from extracted/decomp/TPitch.SetUpFans@004e6014.c, cross-checked against a direct
' capstone disassembly of the original bytes at 0x004E6014 (binary/NSS5.exe), src/recovered/
' TPitch.SetUp.bmx (same CreateKitStrings/CreateKit/GetPaintedFan/LoadAnimImage idiom, same
' "EngineMedia/Match/Pitch/Fans.png" literal, same g_fansimg slot), src/recovered/TKit.CreateKit.bmx
' and src/recovered/TKitStrings.CreateKitStrings.bmx (field offsets/argument order for TKit.newcol
' and TKitStrings), and src/recovered/TPitch.DrawBosses.bmx / src/recovered/TPitch.DrawFans.bmx (the
' readers of the two Globals this body is the sole writer for).
'
' SHAPE FACTS confirmed against the disassembly:
'   1. There is NO `Local kitH:TKit = a0.kitplayer` (or kitA for a1). Every access is the full
'      chain `a0.kitplayer.style` / `a0.kitplayer.newcol[N]`, independently re-fetching [a0+0x2c]
'      from scratch each time (the disassembly re-reads [esi+0x2c] FOUR separate times for the home
'      block alone, once per field). Matches the project-wide "bcc does no CSE" fact already
'      documented in src/recovered/TKit.CreateKit.bmx's own header.
'   2. `a0.kitplayer.style` (styleH) is a separate `Local` declared textually FIRST, evaluated
'      before shirt1H/shirt2H/shortsH, not inline as the CreateKitStrings call's last argument.
'      The disassembly computes style into eax, then shirt1(newcol[1]) into edi, then
'      shirt2(newcol[4]) spilled to [ebp-8], then shorts(newcol[7]) spilled to [ebp-0x1c], and ONLY
'      THEN emits the five pushes for the call (style/"000000"/"404040"/shirt2/shirt1, right-to-left
'      per codegen-patterns.md 16.2). It costs zero bytes (stays live in eax the whole time) since
'      nothing between its declaration and its use touches eax. Same shape for styleA on the away
'      side.
'   3. The a2 dispatch (Case 0 / Case 1, no default) is a `Select a2`, not `If/ElseIf`: a2 is
'      loaded into eax ONCE, both `cmp/je` sit back to back, then a `jmp` skips both case bodies
'      when neither matches (codegen-patterns.md 10.2). As If/ElseIf it would reload a2 from
'      [ebp+0x10] a second time for the ElseIf test, which the disassembly does not do.
'   4. The two "second fan image" colour-clash fallbacks (shirt1<>shorts, shirt1<>shirt2) are
'      spelled with `<>`, not `=`: the disassembly falls straight through into the fallback body on
'      the NOT-equal path and jumps forward over it on the equal path (`cmp eax,0 / je`), the
'      mirror image of the `=` shape TKit.CreateKit.bmx's `If g_kitfiles[0] = "" Then ...` already
'      established (there, `jne` skips the Then-body; here the skip is `je`, so the source-level
'      test itself is inverted).
'   5. The fallback TKitStrings is written back into `ksH`/`ksA` itself (reassigned), not into a
'      fresh `Local ksH2`/`ksH3`. `ksH`/`ksA` is a value that must survive across calls (LoadAnimImage/
'      SetImageHandle/MidHandleImage run between its uses), so it keeps one persistent register
'      (ebx) for the whole home/away block; every branch's "push ebx" before the second CreateKit
'      call reads that same slot. Declaring a distinct `ksH2`/`ksH3` Local instead measurably moves
'      the register allocator's choices for shirt1H/shirt1A (see codegen-patterns.md 22-23 on how
'      introducing or removing a Local changes the interference graph, not just a tie-break).
'   6. The function ends with two bare statement calls, `TPhotographer.SetUpPositions()` and
'      `TCameraMan.SetUpPositions()`, immediately before `Return 0` (extracted/call_sites.tsv:
'      0x004e65f7 -> 0x00c5dc90 = TPhotographer+0x38, 0x004e65fd -> 0x00c5ddf8 = TCameraMan+0x38,
'      both zero-arg, both discarding the Int return value). Despite the function's name, it also
'      repositions the photographer and cameraman for the new lineup.
'
' Builds a team-coloured "boss" (manager) sprite and two team-coloured "fans" sprite variants for
' each side, then re-rolls the whole 100x100 crowd-seat grid that DrawFans reads. Despite the name,
' it ALSO populates the two boss images DrawBosses reads -- an original-source scope quirk,
' preserved faithfully per law 3 (do not improve the original).
'
' GLOBALS -- addresses are fact (python scripts/explain_global.py), names are the established
' corpus choices, not invented here.
'   0x00C5D60C g_fansimg:TImage[]     -- explain_global.py STRONG (forced by src/recovered/
'     TPitch.SetUp.bmx, which builds elements [0..5]). This body is the sole writer of [6..9],
'     reviving the dead dereferences in src/recovered/TPitch.DrawFans.bmx, which reads
'     g_pitch_arr04[6..9] -- the SAME address 0x00C5D60C under DrawFans' own pre-unification
'     provisional name (confirmed: explain_global.py g_pitch_arr04 resolves address=0x00C5D60C,
'     the identical slot g_fansimg is STRONG at).
'   0x00C5D620 g_pitch_arr06:TImage[] -- explain_global.py AMBIGUOUS (only one declaring body so
'     far), but that body is src/recovered/TPitch.DrawBosses.bmx, itself byte-identical verified,
'     which reads g_pitch_arr06[0]/[1] as the home/away boss sprite. This body is DrawBosses' sole
'     writer, confirmed independently by this body's own CreateKit->GetPaintedFan->LoadAnimImage->
'     SetImageHandle(30,118) chain feeding straight into those two slots.
'   0x00C5D614 g_pitch_arr05:Int[,,]  -- explain_global.py AMBIGUOUS (only one declaring body so
'     far: src/recovered/TPitch.DrawFans.bmx, itself byte-identical verified across the
'     toolchain-nondeterminism note). [plane,col,row]; plane 0 = seat's fan-image index, plane 1 =
'     per-seat x jitter, plane 2 = per-seat y jitter. This body is DrawFans' sole writer.
'
' CALL TARGETS (extracted/globals_classtable_slots.tsv + extracted/vtable_map.tsv, cross-checked
' against src/recovered/TKit.CreateKit.bmx / TKitStrings.CreateKitStrings.bmx / TPitch.SetUp.bmx,
' all of which already call these same slots):
'   0x00C5C6AC = TKitStrings+0x30 CreateKitStrings(shirt1$,shirt2$,shorts$,socks$,style$):TKitStrings
'   0x00C5C4B8 = TKit+0x38 CreateKit(:TKitStrings,$):TKit
'   TKit+0x40 = GetPaintedFan(i,i):TPixmap    (variant, colour override; -1 = no override)
'   0x00C59E0C = TClub+0x60 SelectById(i):TClub      0x00C59A20 = TNation+0x58 SelectById(i):TNation
'   0x005AE2BC = LoadAnimImage(:TPixmap,i,i,i,i,i):TImage   (_brl_max2d_LoadAnimImage)
'   0x005AE336 = SetImageHandle(:TImage,f,f)i   (_brl_max2d_SetImageHandle)
'   0x005AE38D = MidHandleImage(:TImage)i       (_brl_max2d_MidHandleImage)
'   0x004A6A30 = _bbStringCompare, i.e. plain BlitzMax `=`/`<>` on two Strings (see src/recovered/
'     TCompetition.SelectByTLA.bmx and src/recovered/TKit.CreateKit.bmx for the `=` shape; the
'     `<>` shape is this body's own colour-clash tests, see SHAPE FACTS 4 above)
'   0x0059F089 = _brl_random_Rand ; FUN(x,1) is source Rand(x) (brl_functions.tsv and corpus
'     convention -- see src/recovered/TPitch.RandomPitchType.bmx, TBall.CheckLongShotRating.bmx,
'     THorse.ResetRands.bmx). Rand(min,max=1): range=max-min; if range>0 the result is
'     [min,max], otherwise [max,min] -- confirmed against tools/blitzmax-legacy-src/mod/brl.mod/
'     random.mod/random.bmx.
'   0x00C5DC90 = TPhotographer+0x38 SetUpPositions()i   0x00C5DDF8 = TCameraMan+0x38
'     SetUpPositions()i (extracted/globals_classtable_slots.tsv; both called as bare statements,
'     Int return value discarded)
'
' FIELDS (extracted/object_model.json):
'   TTeam id=+8(i) kitplayer=+0x2C(:TKit)
'   TKit style=+0xC($) newcol=+0x10([]$)  -- newcol data starts at +0x18 (BBArray convention);
'     [1]=shirt1, [4]=shirt2, [7]=shorts (indices confirmed against TKit.CreateKit.bmx's own
'     k.newcol[1]=a0.shirt1 / [4]=a0.shirt2 / [7]=a0.shorts assignments -- so kitplayer.newcol[7]
'     here is the kit's SHORTS colour, not an arbitrary third colour).
'   TClub nationid=+100(i)   TNation primaryskin=+0x6C(i) secondaryskin=+0x70(i)
'
' STRING LITERALS -- read directly out of binary/NSS5.exe (BBString layout: length at object+8,
' UTF-16 chars at object+0xC), since none of these addresses carry a row in extracted/ghidra/
' strings_with_xrefs.tsv:
'   0x00C752CC "404040"   0x00C6FC58 "000000"   0x00C785BC "800000"   0x00C785A4 "000080"
'   0x00C75670 "PLAIN"    0x00C78558 "EngineMedia/Match/Pitch/Boss.png"
'   0x00C784AC "EngineMedia/Match/Pitch/Fans.png" (byte-for-byte the same literal src/recovered/
'   TPitch.SetUp.bmx already uses for its own "fanfile" Local).
'
' SHAPE NOTES
'   * a0 is home, a1 is away: g_fansimg[6..7] (a0's block) vs [8..9] (a1's block) match
'     TPitch.DrawFans.bmx's own header note "[8] and [9] are the away-colours pair".
'   * a2 selects how the "fan nation" is found: a2=0 looks up a0/a1.id as a TClub and follows its
'     .nationid to a TNation; a2=1 treats a0/a1.id as a TNation id directly. Any other a2 leaves
'     skin1/skin2 at whatever they already held (0 the first time skin1/skin2 are used, in the
'     home block). No Else/default case exists in the original; reproduced exactly, not defended
'     against with an extra branch.
'   * skin2 (local_1c in the decompilation) is computed ONLY in the home (a0) block and is NEVER
'     recomputed for away -- the away block's second fan image is painted with GetPaintedFan(4,-1)
'     regardless, so the stale value is dead there, but the omission itself is preserved
'     (ORIGINAL BEHAVIOUR, VA 0x004E6014, decompiled lines 103-111).
'   * The away boss/fan block does NOT mirror home's use of skin1/skin2: the away BOSS still uses
'     skin1 (freshly recomputed for a1), but BOTH away fan images use hardcoded variant indices 2
'     and 4 instead of skin1/skin2 -- unlike home, which uses skin1 for its boss AND its first fan
'     image, skin2 for its second. Preserved exactly; this reads as an original-source
'     inconsistency, not a reconstruction artefact (law 3).
'   * The "second fan image" colour-clash fallback is genuinely asymmetric between home and away.
'     When shirt1=shorts: home rebuilds TKitStrings as (shorts,shirt2,"000080","000000","PLAIN"),
'     away rebuilds it as (shorts,shirt1,"000080","000000","PLAIN") -- shirt2 vs shirt1 as the
'     second colour. The OTHER fallback branch (shirt1=shirt2) uses the identical
'     (shirt2,shirt1,"800000",...) pairing in BOTH blocks, which is what rules out arbitrary
'     decompiler temp-naming as the explanation for the other branch's difference -- it is a real
'     difference in the original source. Preserved exactly.
'   * The crowd-seat grid ([0..99],[0..99]) always starts a cell at fan-image index 6, has a Rand(5)
'     < 3 chance (roughly 2 in 5) of overwriting it with 7, and otherwise a Rand(4) = 1 chance
'     (roughly 1 in 4) of overwriting it with a uniform Rand(0,5) -- so indices 6/7 are the majority
'     outcome, not a rare exception; images 0-5 (the six generic sheets TPitch.SetUp.bmx builds)
'     are the minority. The order of the two rolls (5-sided first, then conditionally the 4-sided
'     one, then the two jitter rolls) is preserved exactly since it fixes the PRNG call sequence.
' Body-only format: statements only, parameters are a0, a1, a2.
'!Global g_fansimg:TImage[]
'!Global g_pitch_arr06:TImage[]
'!Global g_pitch_arr05:Int[,,]
Local styleH:String = a0.kitplayer.style
Local shirt1H:String = a0.kitplayer.newcol[1]
Local shirt2H:String = a0.kitplayer.newcol[4]
Local shortsH:String = a0.kitplayer.newcol[7]
Local ksH:TKitStrings = TKitStrings.CreateKitStrings(shirt1H, shirt2H, "404040", "000000", styleH)
Local skin1:Int = 0
Local skin2:Int = 0
Select a2
Case 0
	Local natH:TNation = TNation.SelectById(TClub.SelectById(a0.id).nationid)
	skin1 = natH.primaryskin + 1
	skin2 = natH.secondaryskin + 1
Case 1
	Local natH:TNation = TNation.SelectById(a0.id)
	skin1 = natH.primaryskin + 1
	skin2 = natH.secondaryskin + 1
End Select
Local kitBossH:TKit = TKit.CreateKit(ksH, "EngineMedia/Match/Pitch/Boss.png")
Local pixBossH:TPixmap = kitBossH.GetPaintedFan(skin1, -1)
g_pitch_arr06[0] = LoadAnimImage(pixBossH, 64, 128, 0, 9, -1)
SetImageHandle(g_pitch_arr06[0], 30.0, 118.0)
Local kitFansH1:TKit = TKit.CreateKit(ksH, "EngineMedia/Match/Pitch/Fans.png")
Local pixFansH1:TPixmap = kitFansH1.GetPaintedFan(skin1, -1)
g_fansimg[6] = LoadAnimImage(pixFansH1, 64, 128, 0, 30, -1)
MidHandleImage(g_fansimg[6])
Local kitFansH2:TKit
If shirt1H <> shortsH
	ksH = TKitStrings.CreateKitStrings(shortsH, shirt2H, "000080", "000000", "PLAIN")
	kitFansH2 = TKit.CreateKit(ksH, "EngineMedia/Match/Pitch/Fans.png")
Else
	If shirt1H <> shirt2H
		ksH = TKitStrings.CreateKitStrings(shirt2H, shirt1H, "800000", "000000", "PLAIN")
		kitFansH2 = TKit.CreateKit(ksH, "EngineMedia/Match/Pitch/Fans.png")
	Else
		kitFansH2 = TKit.CreateKit(ksH, "EngineMedia/Match/Pitch/Fans.png")
	EndIf
EndIf
Local pixFansH2:TPixmap = kitFansH2.GetPaintedFan(skin2, -1)
g_fansimg[7] = LoadAnimImage(pixFansH2, 64, 128, 0, 30, -1)
MidHandleImage(g_fansimg[7])
Local styleA:String = a1.kitplayer.style
Local shirt1A:String = a1.kitplayer.newcol[1]
Local shirt2A:String = a1.kitplayer.newcol[4]
Local shortsA:String = a1.kitplayer.newcol[7]
Local ksA:TKitStrings = TKitStrings.CreateKitStrings(shirt1A, shirt2A, "404040", "000000", styleA)
Select a2
Case 0
	Local natA:TNation = TNation.SelectById(TClub.SelectById(a1.id).nationid)
	skin1 = natA.primaryskin + 1
Case 1
	Local natA:TNation = TNation.SelectById(a1.id)
	skin1 = natA.primaryskin + 1
End Select
Local kitBossA:TKit = TKit.CreateKit(ksA, "EngineMedia/Match/Pitch/Boss.png")
Local pixBossA:TPixmap = kitBossA.GetPaintedFan(skin1, -1)
g_pitch_arr06[1] = LoadAnimImage(pixBossA, 64, 128, 0, 9, -1)
SetImageHandle(g_pitch_arr06[1], 30.0, 118.0)
Local kitFansA1:TKit = TKit.CreateKit(ksA, "EngineMedia/Match/Pitch/Fans.png")
Local pixFansA1:TPixmap = kitFansA1.GetPaintedFan(2, -1)
g_fansimg[8] = LoadAnimImage(pixFansA1, 64, 128, 0, 30, -1)
MidHandleImage(g_fansimg[8])
Local kitFansA2:TKit
If shirt1A <> shortsA
	ksA = TKitStrings.CreateKitStrings(shortsA, shirt1A, "000080", "000000", "PLAIN")
	kitFansA2 = TKit.CreateKit(ksA, "EngineMedia/Match/Pitch/Fans.png")
Else
	If shirt1A <> shirt2A
		ksA = TKitStrings.CreateKitStrings(shirt2A, shirt1A, "800000", "000000", "PLAIN")
		kitFansA2 = TKit.CreateKit(ksA, "EngineMedia/Match/Pitch/Fans.png")
	Else
		kitFansA2 = TKit.CreateKit(ksA, "EngineMedia/Match/Pitch/Fans.png")
	EndIf
EndIf
Local pixFansA2:TPixmap = kitFansA2.GetPaintedFan(4, -1)
g_fansimg[9] = LoadAnimImage(pixFansA2, 64, 128, 0, 30, -1)
MidHandleImage(g_fansimg[9])
For Local i:Int = 0 To 99
	For Local j:Int = 0 To 99
		g_pitch_arr05[0, j, i] = 6
		If Rand(5) < 3
			g_pitch_arr05[0, j, i] = 7
		Else
			If Rand(4) = 1
				g_pitch_arr05[0, j, i] = Rand(0, 5)
			EndIf
		EndIf
		g_pitch_arr05[1, j, i] = Rand(-2, 2)
		g_pitch_arr05[2, j, i] = Rand(-1)
	Next
Next
TPhotographer.SetUpPositions()
TCameraMan.SetUpPositions()
Return 0
