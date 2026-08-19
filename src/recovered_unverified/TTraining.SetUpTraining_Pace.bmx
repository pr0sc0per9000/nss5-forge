' TTraining.SetUpTraining_Pace
' VA 0x0057C6D2   1613 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x38
' byte-identical vs NSS5.exe
' sig ()i   NOT YET BYTE-VERIFIED -- reconstructed statement-by-statement from
' scripts/disasm.py 0x0057c6d2 400 (the raw x86, not just Ghidra's C -- see below for why)
' plus the five already-verified siblings TTraining.SetUpTraining_Dribbling/_Passing/
' _Shooting/_Heading/_Tackling and TScreen_Controls.RefreshButtons/
' TPanel_Controls.RenderTraining. Body-only format: statements only, matching the current
' house style (TTraining.SetUpTraining_Dribbling.bmx, most recently rewritten this way).
'
' REFINE PASS (score was 15.7%, first diff at byte 10): full re-disassembly of all 1613
' bytes (scripts/disasm.py 0x0057c6d2 1613) confirmed every statement already matched
' EXCEPT the trial-message block's `s` construction, which was one flat `+` expression --
' see the corrected note below for the fix (four statements with `:+`, and GetText fused
' with its first .Replace() into one statement). Every other statement, including the full
' 10-way Select and the tail pole/line loop, was individually re-verified byte-for-byte
' against the disassembly and left untouched. The byte-10 first-difference itself is the
' LogLine call's pushed string address / call target, which is a whole-program layout
' artifact (see TPlayer.HeadBallAdvanced.bmx / TProfile.GetHashtaglessName.bmx: the oracle
' masks relocation addresses on a real match), not a statement to fix in this file.
' WHY THE RAW DISASSEMBLY WAS NECESSARY, NOT JUST GHIDRA'S C
'  * Every TPitch.YardsToPixels() call site prints with EMPTY parens in Ghidra's decompile
'    (the Float argument is passed on the x87 stack, which Ghidra does not attribute to the
'    call as a C argument) -- so the two literal offsets this function passes (10.0, -20.0)
'    are invisible in the .c file and were read directly off the pushed immediate bytes
'    (0x41200000, 0xC1A00000) at the two call sites, the same "raw immediate, not a data
'    reference" shape TTraining.Call.bmx's own 30.0 literal uses.
'  * The trial-message block's four TOptions.GetButtonLabel(...) calls each show only ONE
'    visible argument in Ghidra's C, looking like a 1-arg call -- but TOptions.GetButtonLabel
'    is (i)$ and did receive one real Int argument; what is actually happening is the
'    OPPOSITE of the usual merge trap (extra args, not missing ones): a ", " (or "$keypause"/
'    "$keykick") literal is pushed BEFORE the array-element argument and is only ever popped
'    by the FOLLOWING _bbStringConcat/String.Replace call, so Ghidra's own per-call arg count
'    undercounts by one every time. Read off `add esp, N` after each `call` to see exactly
'    what each callee actually popped.
'
' SHAPE NOTES (each confirmed against the bytes)
'  * `g_training_int04 = g_profile.pace / 10 + 1` is ONE expression (idiv then add 1, no
'    intermediate store) -- the Heading-style single-expression formula, not Dribbling's
'    `*2+10` then `:/10` two-statement idiom. `ClampInt(Varptr g_training_int04, 1, 10)`: a
'    10-level stat (like Heading/Passing's level scheme), not a 20-level one.
'  * The trial-message block (`g_training_int04 = 1 And g_profile.contractwage = 0`) is far
'    more elaborate than any other SetUpTraining_* sibling's, and reads as follows off the
'    bytes, in order:
'      1. Build `s` from FOUR SEPARATE STATEMENTS, not one flat `+` chain -- the raw
'         disassembly (0x0057C7EA-0x0057C898) calls GetButtonLabel in FORWARD source order
'         (LEFT, RIGHT, UP, DOWN) and each of the middle two terms computes its OWN
'         "label + sep" pair as a self-contained unit (a fresh `call _bbStringConcat`)
'         BEFORE that pair is concatenated onto the running total -- the running total is
'         re-homed into ebx (`mov ebx,eax`) after every statement. A single flat
'         `A + ", " + B + ", " + C + ", " + D` expression compiles completely differently:
'         cross-checked against TPanel_Controls.RenderTraining.bmx's own byte-identical
'         `s = GetButtonLabel(a)+","+GetButtonLabel(c)+","+GetButtonLabel(b)+","+GetButtonLabel(d)`,
'         a genuine one-expression join evaluates its leaves in REVERSE source order (last
'         term first) with every intermediate value staying on the native stack (`push eax`,
'         never `mov ebx,eax`) -- the opposite of what this function's bytes show. The
'         real shape, confirmed further against TClub.WriteDataMobile.bmx's documented
'         "the separator groups with the FIELD, which is what `s :+ sep + x` produces"
'         house idiom, is:
'           `Local s:String = GetButtonLabel(arr04[idx]) + ", "`
'           `s :+ GetButtonLabel(arr05[idx]) + ", "`
'           `s :+ GetButtonLabel(arr02[idx]) + ", "`
'           `s :+ GetButtonLabel(arr03[idx])`             (last term, no trailing separator)
'         (arr04/05/02/03 are exactly TScreen_Controls.RefreshButtons's btn_left/btn_right/
'         btn_up/btn_down arrays) -- LEFT, RIGHT, UP, DOWN, comma-joined in that byte order,
'         not the more natural up/down/left/right.
'      2. `s = Lower(s)`, then `If s.Contains("CURSOR")` -- and BOTH arms of that If go
'         nowhere: the True arm's own `Lower(GetText("controls_CursorKeys"))` result is never
'         stored (no `mov [mem], eax` follows it before the next block clobbers eax), so it
'         is reproduced as a bare, dead expression statement (law 3: preserve, don't tidy).
'         `s` itself (the 4-key list) is never read again either -- the whole block 1/2 exists
'         only to evaluate this one dead condition.
'      3. `s = GetText("CMESSAGE_TRIALPACE").Replace("$keypause", Lower(TOptions.GetButtonLabel(g_options_arr10[g_options_int01])))`
'         -- GetText and the FIRST .Replace() are ONE FUSED STATEMENT: the GetText call's
'         result flows straight into the Replace call via `push eax` with no intervening
'         `mov ebx,eax`, and the Lower/GetButtonLabel(pause) operand is evaluated and pushed
'         BEFORE the GetText call runs -- the same reverse-leaf-order evaluation the
'         RenderTraining cross-check established for a single real expression. THEN a
'         genuinely separate second statement:
'         `s = s.Replace("$keykick", Lower(TOptions.GetButtonLabel(g_options_arr06[g_options_int01])))`
'         -- this one DOES read `s` back out of ebx first (`push ebx`), proving the statement
'         boundary sits between the two `.Replace()` calls, not before the first one.
'         (arr10/arr06 are RefreshButtons's btn_pause/btn_kick arrays). Confirmed as
'         String.Replace (0x004A75B0, 3-arg cdecl call) by cross-reference with
'         TProfile.GetHashtaglessName.bmx's identical callee and its own chained
'         `name.Replace("@", "").Replace("#", "")` fused-call precedent.
'      4. `g_traininglabel1.SetText(s, "", -1, -1)` then a second, much simpler
'         `g_traininglabel3.SetText(GetText("CMESSAGE_TRIALTIME"), "", -1, -1)`.
'  * `Local gap:Int = 10` / `Local wobble:Int = 0` declared right after the trial block (same
'    two Locals, same initial values, same order as Dribbling's), then a 10-way NUMERIC
'    `Select g_training_int04` (Case 1..10, no Default -- pattern 10.2, confirmed by the
'    back-to-back `cmp/je` chain at 0x0057C990). Every case sets g_training_int20, gap and
'    g_training_int06 in that order; Cases 3/5/7/9 additionally set wobble (to 1/2/3/4) as a
'    fourth statement. All ten cases' immediates were read directly off the `mov` instructions
'    at 0x0057C9E7-0x0057CB35, not inferred from a sibling.
'  * `gap = Int(TPitch.YardsToPixels(gap))` -- Dribbling's own idiom, reused verbatim (same
'    Local reassigned in place).
'  * `g_training_int11 = Int(-g_player_int16 + TPitch.YardsToPixels(10.0))` -- same shape as
'    Dribbling/Heading/Shooting's own int11 formula, but with Pace's own offset 10.0 where
'    they use 5.0.
'  * `g_training_int12 = Int(TPitch.YardsToPixels(-20.0))` -- the exact same -20.0 Dribbling
'    uses for its own g_training_int12.
'  * `g_object811`/`g_object812` (TTrainingZone; CERTAIN per scripts/explain_global.py, 2
'    bodies unanimous with TTraining.UpdateDribbling/UpdatePace.bmx -- NOT the
'    "g_trainingzone_start/end" names TTraining.SetUpTraining_Dribbling.bmx's own prose uses
'    for its structurally identical pair of calls) are built with the same "00FF00"/"FF0000",
'    (g_training_int11, g_training_int12, 2.0) shape Dribbling already established; the end
'    zone sits at `g_training_int11 + (g_training_int20 + 1) * gap`.
'  * Tail loop is byte-for-byte Dribbling's ELSE-branch shape (single-file poles with vertical
'    jitter, no cone course): `TPole.Create(x, y, "FFFF00")`, then `TTrainingLine.Create(x, y,
'    lastx, lasty, "00FF00")` only when `i > 1`, then `lastx = x; lasty = y`. Ends with
'    `TTrainingLine.ActivateNextLine()` then the implicit `Return 0`.
'
' Globals (addresses and tiers from scripts/explain_global.py; every String/Object store's
' retain/release pair is compiler-inserted by the `=` assignment, not written by hand here):
'   0x00C6F028 g_profile:TProfile (.pace=+0xA4, .contractwage=+0x78 -- object_model.json)
'   0x00C6CF94 g_training_int04   0x00C6CF9C g_training_int06   0x00C6CFA4 g_training_int08$
'   0x00C6CFA8 g_training_int09$  0x00C6CFAC g_training_int10$ -- all five AMBIGUOUS per the
'     auto-aligner but unanimously established by name across TTraining.SetUpTraining_
'     Dribbling/_Passing/_Shooting/_Heading/_Tackling.bmx (5-6 bodies each).
'   0x00C6CFB8 g_traininglabel1:TLabel (STRONG, 6 bodies)   0x00C6CFC0 g_traininglabel3:TLabel
'     (STRONG, 1 body) -- both TGadget slot 0x64 SetText, inherited, same as every sibling.
'   0x00C6CFD0 g_training_int11   0x00C6CFD4 g_training_int12   0x00C6CFF4 g_training_int20
'     -- AMBIGUOUS per the auto-aligner, established by name across the same five siblings.
'   0x00C6CFC8 g_object811:TTrainingZone   0x00C6CFCC g_object812:TTrainingZone (CERTAIN, 2
'     bodies unanimous -- TTraining.UpdateDribbling.bmx/TTraining.UpdatePace.bmx).
'   0x00C5D634 g_player_int16:Int (STRONG, 21 bodies; the same Global Dribbling/Heading/
'     Shooting use for their own `-g_player_int16 + YardsToPixels(...)` int11 formula).
'   0x00C5D1A8 g_options_int01:Int (CERTAIN, 10 bodies -- current input-device index; same
'     Global TPanel_Controls.RenderTraining/TScreen_Controls.RefreshButtons use).
'   0x00C5D1B4 g_options_arr02:Int[] (up)   0x00C5D1BC g_options_arr03:Int[] (down)
'   0x00C5D1C4 g_options_arr04:Int[] (left)   0x00C5D1CC g_options_arr05:Int[] (right)
'   0x00C5D1D4 g_options_arr06:Int[] (kick)   0x00C5D1F4 g_options_arr10:Int[] (pause) -- all
'     six named and typed by the byte-verified TScreen_Controls.RefreshButtons.bmx, which also
'     resolves the [0x00C5D54C]=TOptions.GetButtonLabel(i)$ class-table slot this function
'     calls through.
' Class-table slot calls: TPitch+0x6C=YardsToPixels(f)f, TOptions+0x34=GetButtonLabel(i)$,
'   TTrainingZone+0x48=Create(i,i,f,$,$):TTrainingZone (table VA 0x00C6DAAC+0x48=0x00C6DAF4,
'   confirmed by the 0x40000000=2.0f immediate argument matching Dribbling's own zone calls),
'   TPole+0x48=Create(i,i,$)i (table VA 0x00C6D9A4+0x48=0x00C6D9EC), TTrainingLine+0x48=
'   Create(i,i,i,i,$):TTrainingLine and +0x50=ActivateNextLine()i (table VA 0x00C6DC1C).
' Literals (scripts/harness.read_string against NSS5.exe, none invented): "SetUpTraining_Pace"
'   "Pace Training" "Level" " " "CTRAINING_PACE1" ", " "CURSOR" "controls_CursorKeys"
'   "CMESSAGE_TRIALPACE" "$keypause" "CMESSAGE_TRIALTIME" "$keykick" "00FF00" "FF0000"
'   "FFFF00"; empty-string arguments use the corpus-wide "" constant 0x00C5D284.
'!Global g_profile:TProfile
'!Global g_training_int04:Int
'!Global g_training_int06:Int
'!Global g_training_int08:String
'!Global g_training_int09:String
'!Global g_training_int10:String
'!Global g_traininglabel1:TLabel
'!Global g_traininglabel3:TLabel
'!Global g_training_int11:Int
'!Global g_training_int12:Int
'!Global g_training_int20:Int
'!Global g_object811:TTrainingZone
'!Global g_object812:TTrainingZone
'!Global g_player_int16:Int
'!Global g_options_int01:Int
'!Global g_options_arr02:Int[]
'!Global g_options_arr03:Int[]
'!Global g_options_arr04:Int[]
'!Global g_options_arr05:Int[]
'!Global g_options_arr06:Int[]
'!Global g_options_arr10:Int[]
LogLine("SetUpTraining_Pace")
g_training_int04 = g_profile.pace / 10 + 1
ClampInt(Varptr g_training_int04, 1, 10)
g_training_int08 = GetText("Pace Training")
g_training_int09 = GetText("Level") + " " + g_training_int04
g_training_int10 = GetText("CTRAINING_PACE1")
If g_training_int04 = 1 And g_profile.contractwage = 0
	Local s:String = TOptions.GetButtonLabel(g_options_arr04[g_options_int01]) + ", "
	s :+ TOptions.GetButtonLabel(g_options_arr05[g_options_int01]) + ", "
	s :+ TOptions.GetButtonLabel(g_options_arr02[g_options_int01]) + ", "
	s :+ TOptions.GetButtonLabel(g_options_arr03[g_options_int01])
	s = Lower(s)
	If s.Contains("CURSOR")
		Lower(GetText("controls_CursorKeys"))
	EndIf
	s = GetText("CMESSAGE_TRIALPACE").Replace("$keypause", Lower(TOptions.GetButtonLabel(g_options_arr10[g_options_int01])))
	s = s.Replace("$keykick", Lower(TOptions.GetButtonLabel(g_options_arr06[g_options_int01])))
	g_traininglabel1.SetText(s, "", -1, -1)
	g_traininglabel3.SetText(GetText("CMESSAGE_TRIALTIME"), "", -1, -1)
End If
Local gap:Int = 10
Local wobble:Int = 0
Select g_training_int04
	Case 1
		g_training_int20 = 3
		gap = 10
		g_training_int06 = 60
	Case 2
		g_training_int20 = 4
		gap = 8
		g_training_int06 = 20
	Case 3
		g_training_int20 = 5
		gap = 8
		g_training_int06 = 18
		wobble = 1
	Case 4
		g_training_int20 = 6
		gap = 6
		g_training_int06 = 16
	Case 5
		g_training_int20 = 7
		gap = 6
		g_training_int06 = 14
		wobble = 2
	Case 6
		g_training_int20 = 8
		gap = 5
		g_training_int06 = 12
	Case 7
		g_training_int20 = 9
		gap = 5
		g_training_int06 = 10
		wobble = 3
	Case 8
		g_training_int20 = 10
		gap = 4
		g_training_int06 = 10
	Case 9
		g_training_int20 = 11
		gap = 4
		g_training_int06 = 10
		wobble = 4
	Case 10
		g_training_int20 = 12
		gap = 4
		g_training_int06 = 10
End Select
gap = Int(TPitch.YardsToPixels(gap))
g_training_int11 = Int(-g_player_int16 + TPitch.YardsToPixels(10.0))
g_training_int12 = Int(TPitch.YardsToPixels(-20.0))
g_object811 = TTrainingZone.Create(g_training_int11, g_training_int12, 2.0, "00FF00", "")
g_object812 = TTrainingZone.Create(g_training_int11 + (g_training_int20 + 1) * gap, g_training_int12, 2.0, "FF0000", "")
Local lastx:Int = 0
Local lasty:Int = 0
For Local i:Int = 1 To g_training_int20
	Local x:Int = g_training_int11 + i * gap
	Local y:Int = Int(g_training_int12 + TPitch.YardsToPixels(Rand(-wobble, wobble)))
	TPole.Create(x, y, "FFFF00")
	If i > 1
		TTrainingLine.Create(x, y, lastx, lasty, "00FF00")
	End If
	lastx = x
	lasty = y
Next
TTrainingLine.ActivateNextLine()
