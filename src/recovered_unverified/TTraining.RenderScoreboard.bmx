' TTraining.RenderScoreboard
' VA 0x005811EA   1626 bytes   KIND=Function (static, no implicit Self)   SIG=(f)i   class-table slot 0x8C
' Body-only format: statements only; parameter is a0:Float -- the render-interpolation
' fraction blended between last-tick and current-tick ticker scroll position (see
' g_train_scrollx/g_train_scrollx2 below; TTraining.Update sets the "current" one from the
' "previous" one every tick, and this function tweens between them for smooth motion).
'
' ASSUMPTIONS -- module Global NAMES are ours except where the reflection tables already
' fixed them; DECLARED TYPES are load-bearing (they select the vtable slot / field offset).
' Resolved with scripts/explain_global.py plus cross-checking every TTraining/TPanel_Controls
' sibling already in src/recovered/; ties are flagged UNCERTAIN rather than guessed silently.
'
'   0x00C6CF84 g_train_ballicon:TImage       -- NEW slot, first user in the corpus. The not-
'     yet-reconstructed TTraining.SetUpTraining (VA 0x0057BF1F) loads it from
'     "EngineMedia/Match/Other/BallIcon.png" (confirmed with harness.read_string at the
'     literal address 0x00C91E44) immediately before the g_training_int22 "calls remaining"
'     counter below -- construction-site adjacency ties icon to counter.
'   0x00C6CF88 g_train_goalicon:TImage       -- NEW slot, same construction site,
'     "EngineMedia/Match/Other/GoalIcon.png" (0x00C91E98), paired with g_training_int21.
'   0x00C6CF8C g_train_stopwatchicon:TImage  -- NEW slot, same construction site,
'     "EngineMedia/Match/Other/StopWatch.png" (0x00C91EEC), paired with g_training_int06
'     (the per-drill seconds value, e.g. 60/20 in SetUpTraining_Dribbling -- a stopwatch
'     icon next to a seconds count is the obvious reading).
'   0x00C6CF94 g_training_int04:Int  -- drill LEVEL; unanimous across every SetUpTraining_*
'     sibling ("Level " + g_training_int04).
'   0x00C6CF98 g_training_int05:Int  -- UNCERTAIN vs "g_training_state". The corpus is split:
'     TTraining.Success/.Render/.PlayerCanMove/.TrainingSetPiece all declare a
'     "g_training_state", but re-deriving each body's own declares-vs-touches pairing shows
'     only Success's actually lands on 0x00C6CF98 -- Render/PlayerCanMove/TrainingSetPiece
'     each pair their lone "g_training_state" to 0x00C6CF90 instead, and TTraining.Update's
'     "g_train_state" claim pairs to 0x00C6CFFC. That leaves ONE clean body for
'     "g_training_state" at this address. Meanwhile THREE bodies -- TPanel_Controls.
'     RenderTraining, TTraining.UpdateDribbling, TTraining.UpdatePace -- unanimously and
'     unambiguously (no reordering candidates, tight 5/15-item declare/touch lists) pair
'     "g_training_int05" to this exact address, and it slots cleanly into the established
'     int03(0x90)/int04(0x94)/int06(0x9C) numbering run. Went with g_training_int05.
'   0x00C6CF9C g_training_int06:Int  -- per-drill seconds value. Majority name (6
'     SetUpTraining_* bodies, all cleanly paired) over TTraining.Update's lone
'     "g_train_counter" claim.
'   0x00C6CFA4 g_training_int08:String  -- drill headline, e.g. GetText("Dribbling Training").
'   0x00C6CFA8 g_training_int09:String  -- drill subtitle, e.g. GetText("Level")+" "+int04.
'   0x00C6CFAC g_training_int10:String  -- scrolling instructions text; drawn here at the
'     tween'd `tickerx` position (see a0 above), corroborating TTraining.Update's own use of
'     this SAME address as the string it feeds to GetTxtWidth for the scroll wrap check.
'     All three int08/int09/int10 are the dominant naming across FIVE independent
'     SetUpTraining_* bodies (Dribbling/Flair/Heading/Passing/Shooting), overriding the
'     "headline"/"message"/"scrolltext"/"msg1"/"msg2"/"s1"/"s2" names Success/Fail/TimeUp/
'     Update each separately picked for the same three addresses.
'   0x00C6CFB0 g_train_scrollx:Float   0x00C6CFB4 g_train_scrollx2:Float
'     (TTraining.Update: current- / previous-tick ticker scroll-x; no competing claim on
'     either address.)
'   0x00C6CFB8 g_traininglabel1:TLabel   0x00C6CFBC g_traininglabel2:TLabel
'   0x00C6CFC0 g_traininglabel3:TLabel   0x00C6CFC4 g_traininglabel4:TLabel
'     (TTraining.ClearUpTraining / SetUpTraining_Flair et al., dominant naming; note
'     SetUpTraining_Dribbling's prose calls 0x00C6CFB8 "g_traininglabel_msg" instead --
'     a minority, uncorroborated claim, not used here.)
'   0x00C6CFF8 g_training_int21:Int   0x00C6CFFC g_training_int22:Int
'     ("goals left" / "calls remaining" counters -- CERTAIN tier, 5- and 7-body agreement
'     per explain_global.py, independently corroborated by the Goal/Ball icon construction
'     site above.)
'   0x00C61724 g_screen_top:Float  -- UNCERTAIN. Sole claim is TTraining.Update (same Type
'     as this function). TGadget.UpdateToolTip separately claims this address for
'     "g_screen_mousex" (a different Type, and a poor semantic fit here -- adding a live
'     mouse-x reading to a label's x-position makes little sense for a scoreboard readout).
'     Went with the same-Type sibling per the reconstruction guide's source priority.
'   0x00C6D010 g_train_fade:Float  -- TTraining.Update (sole claim); also exactly the first
'     argument TPanel_Controls.RenderTraining(f,f)i expects below, which corroborates the
'     type even though it can't corroborate the name.
'   0x00C6EFE4 g_screen_w:Int   0x00C6EFE8 g_screen_h:Int
'     g_screen_h is CERTAIN. g_screen_w is AMBIGUOUS by pure positional alignment (the tool
'     also floats g_engine_gfxw/g_scr_w/g_scrw as 1-2-body STRONG alternates), but FIVE
'     independent bodies -- TEngine.RenderScoreboard (this function's closest analogue),
'     TGadget.UpdateToolTip, TBlackJack.CheckPlayerScore, TBlackJack.DealersTurn,
'     TScreen_Negotiate.Fail, TTraining.Update -- all use "g_screen_w" paired with the
'     CERTAIN g_screen_h at the very next dword, so used here for the same reason.
'   1.0 / 164.0 / 20.0 / 2.0 are Float LITERALS read straight out of the exe at
'     0x00C9292C/0x00C92930/0x00C92934/0x00C92938 (same data region, same nature, as the
'     34.0 literal TPanel_Controls.RenderTraining documents at 0x00C92E18) -- NOT Globals.
'
' CALL TARGETS RESOLVED (extracted/globals_classtable_slots.tsv)
'   0x00C5BB34 = TEngine+0x104   DrawMyText($,f,f,i,i,f,f,$,i)i -> TEngine.DrawMyText(...)
'   0x00C6DE8C = TPanel_Controls+0x34 RenderTraining(f,f)i      -> TPanel_Controls.RenderTraining(...)
'   0x00C6DE9C = TPanel_Controls+0x44 RenderKickToContinue()i   -> TPanel_Controls.RenderKickToContinue()
'   0x005AD711 DrawImage, 0x005AD7C8 DrawImageRect -- brl.max2d, bare calls (brl_functions.tsv;
'     confirmed idiom in TDrawOb.RenderAll / TEngine.RenderScoreboard).
'   0x004A7AC0 _bbStringFromInt -- the two "single-argument call after 8 stack pushes" call
'     sites are the well-known phantom-parameter Ghidra artifact (the surrounding DrawMyText
'     push sequence is still mid-flight when this call executes); written as plain
'     `String(n)`, matching TEngine.RenderScoreboard's own `String(g_fixture.score1)`.
'   0x00C6F34C/0x00C6F3B0 resolve (CERTAIN, "agrees with verified pair") to
'     g_kits_img1:TImage / g_kits_img2:TImage -- the SAME two Globals TScreen_Kits.Draw uses
'     for its kit preview images. TEngine.RenderScoreboard's own header guesses "g_sbbar1"/
'     "g_sbbar2" for this pair instead, but that guess is uncorroborated by the tool (byte
'     match in reloc mode masks data addresses, so it cannot itself prove which address a
'     Global occupies) -- these look like a pair of generic "current background bar image"
'     slots reloaded per screen, and the CERTAIN resolution is used here.
'   TLabel slot 0x44 = Draw()i (vtable_map.tsv); fields from object_model.json TGadget:
'     +0x10 txt:$  +0x20 x:f  +0x24 y:f  +0x2C w:f.
'
' NOTES
'   * The screen_h/2 and screen_w/2 scratch values are freshly recomputed in each branch
'     that needs them (Ghidra shows one reused `iVar3`, but the branches are mutually
'     exclusive or sequential, so recomputation is behaviourally identical).
'
' PASS 2 -- REFINED AGAINST THE RAW DISASSEMBLY (score was 4.1%, first-diff at byte 7)
'   scripts/disasm.py 0x005811ea 1626 was walked in full (not just the Ghidra C). Two
'   structural fixes, both confirmed against the machine code, not guessed:
'
'   1. THE OUTER DISPATCH IS Select, NOT If/ElseIf. The prologue's `mov eax,[..cf98] /
'      cmp eax,0 / je / cmp eax,1 / je / cmp eax,2 / je / jmp end` is the textbook
'      "load subject once, back-to-back compares" Select shape (same idiom documented in
'      TTraining.Update.bmx), and `je` for value 1 lands on a bare `jmp end` -- an EMPTY
'      Case 1 sitting between Case 0 and Case 2. That's what Ghidra's
'      `(DAT_..cf98 != 1) && (DAT_..cf98 == 2)` compound actually decompiles from, per the
'      guide's own "Select loads the subject once" warning. Rewritten as
'      `Select g_training_int05 / Case 0 ... / Case 1 / Case 2 ... / End Select`.
'
'   2. THE THREE COUNTER-ICON BLOCKS (calls-remaining ball / seconds stopwatch / goals
'      left) USE TWO HOISTED Int LOCALS, NOT LITERAL CONSTANTS. This is the actual cause
'      of the missing `push esi` at byte 7 (the prologue reserves ebx+esi for the whole
'      function; the earlier "cy" Local alone only needs ebx). Walking the tail
'      (0x00581663 on):
'        `mov esi,0x28 / mov ebx,0x14`            -- unconditional, right after End Select
'      then per icon: DrawImage's x/y args are read straight from esi/ebx (plain `mov
'      [ebp-8],esi; fild`, an Int->Float local read -- a literal float would instead be a
'      single `fld` from the constant table, as g_traininglabel2.x=20.0 does a few lines
'      earlier), and DrawMyText's x/y args are esi+30 / ebx-20 computed via register
'      arithmetic (`sub eax,0x14` / `add esi,0x1e`) -- again arithmetic on a register, not
'      an immediate push. ebx (the shared "y") is read through an untouched temp in the
'      first two blocks (must survive for the next block) and only clobbered in place in
'      the third (its last live use) -- pure liveness-driven register reuse by the
'      compiler, not a different expression per block. esi (the shared "x") IS re-derived
'      fresh at the top of blocks 2 and 3 (`mov esi,[..efe4]; .../ sar esi,1; sub
'      esi,0x50` for cx-80, then a plain `mov esi,[..efe4]; sub esi,0x96` for screen_w-150)
'      -- confirming a genuine reassignment, not incremental drift. Reconstructed as:
'        `Local icon_x:Int = 40` / `Local icon_y:Int = 20`  (before the three Ifs)
'        ballicon:     DrawImage(x,y,0)        DrawMyText(..., x+30, y-20, ...)
'        stopwatch:    icon_x = g_screen_w/2 - 80   then same two calls, "FFFF00"
'        goalicon:     icon_x = g_screen_w - 150    then DrawMyText x+50 (not +30)
'      Values cross-checked against Ghidra's resolved offsets (-200/-202/+98,
'      -180/-182/+118, 70/0, cx-50/0, screen_w-100/0, etc.) -- all matched already; only
'      the SOURCE FORM (literal vs hoisted Local) was wrong, which is what the register
'      count -- and therefore the prologue -- depends on.

'!Global g_train_scrollx:Float
'!Global g_train_scrollx2:Float
'!Global g_training_int05:Int
'!Global g_training_int04:Int
'!Global g_screen_top:Float
'!Global g_screen_h:Int
'!Global g_traininglabel1:TLabel
'!Global g_traininglabel2:TLabel
'!Global g_traininglabel3:TLabel
'!Global g_traininglabel4:TLabel
'!Global g_screen_w:Int
'!Global g_kits_img1:TImage
'!Global g_kits_img2:TImage
'!Global g_training_int08:String
'!Global g_training_int09:String
'!Global g_training_int10:String
'!Global g_training_int22:Int
'!Global g_train_ballicon:TImage
'!Global g_training_int06:Int
'!Global g_train_stopwatchicon:TImage
'!Global g_training_int21:Int
'!Global g_train_goalicon:TImage
'!Global g_train_fade:Float

Local tickerx:Float = g_train_scrollx * a0 + g_train_scrollx2 * (1.0 - a0)
Select g_training_int05
	Case 0
		If g_training_int04 = 1
			g_traininglabel1.x = g_screen_top + 164.0
			g_traininglabel1.y = g_screen_h - 184
			g_traininglabel1.Draw()
			If g_traininglabel2.txt.Length <> 0
				g_traininglabel2.x = 20.0
				g_traininglabel2.Draw()
			EndIf
			If g_traininglabel3.txt.Length <> 0
				g_traininglabel3.x = g_screen_w / 2 - g_traininglabel3.w / 2.0
				g_traininglabel3.Draw()
			EndIf
			If g_traininglabel4.txt.Length <> 0
				g_traininglabel4.x = (g_screen_w - 20) - g_traininglabel4.w
				g_traininglabel4.Draw()
			EndIf
		Else
			Local cy:Int = g_screen_h / 2
			DrawImageRect(g_kits_img1, 0, cy - 200, g_screen_w, 300.0, 0)
			DrawImageRect(g_kits_img2, 0, cy - 202, g_screen_w, 4.0, 0)
			DrawImageRect(g_kits_img2, 0, cy + 98, g_screen_w, 4.0, 0)
			TEngine.DrawMyText(g_training_int08, g_screen_w / 2, cy - 120, 1, 1, 1.0, 1.0, "FFFFFF", 1)
			TEngine.DrawMyText(g_training_int09, g_screen_w / 2, cy - 20, 1, 1, 1.0, 1.0, "FFFF00", 0)
			TEngine.DrawMyText(g_training_int10, tickerx, cy + 50, 0, 1, 1.0, 1.0, "FFFFFF", 0)
		EndIf
	Case 1
	Case 2
		Local cy:Int = g_screen_h / 2
		DrawImageRect(g_kits_img1, 0, cy - 180, g_screen_w, 300.0, 0)
		DrawImageRect(g_kits_img2, 0, cy - 182, g_screen_w, 4.0, 0)
		DrawImageRect(g_kits_img2, 0, cy + 118, g_screen_w, 4.0, 0)
		TEngine.DrawMyText(g_training_int08, g_screen_w / 2, cy - 100, 1, 1, 1.0, 1.0, "FFFFFF", 1)
		TEngine.DrawMyText(g_training_int09, g_screen_w / 2, cy, 1, 1, 1.0, 1.0, "FFFF00", 0)
		TEngine.DrawMyText(g_training_int10, tickerx, cy + 70, 0, 1, 1.0, 1.0, "FFFFFF", 0)
		TPanel_Controls.RenderKickToContinue()
End Select
Local icon_x:Int = 40
Local icon_y:Int = 20
If g_training_int22 > -1
	DrawImage(g_train_ballicon, icon_x, icon_y, 0)
	TEngine.DrawMyText(String(g_training_int22), icon_x + 30, icon_y - 20, 0, 0, 1.0, 1.0, "FFFFFF", 1)
EndIf
If g_training_int06 > -1
	icon_x = g_screen_w / 2 - 80
	DrawImage(g_train_stopwatchicon, icon_x, icon_y, 0)
	TEngine.DrawMyText(String(g_training_int06), icon_x + 30, icon_y - 20, 0, 0, 1.0, 1.0, "FFFF00", 1)
EndIf
If g_training_int21 > -1
	icon_x = g_screen_w - 150
	DrawImage(g_train_goalicon, icon_x, icon_y, 0)
	TEngine.DrawMyText(String(g_training_int21), icon_x + 50, icon_y - 20, 0, 0, 1.0, 1.0, "FFFFFF", 1)
EndIf
If g_training_int05 <> 2
	TPanel_Controls.RenderTraining(g_train_fade, g_screen_h - 184)
EndIf
