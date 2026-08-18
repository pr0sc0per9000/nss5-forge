' TScreenMessage.Draw -- NOT VERIFIED. ours 1113 / orig 1119 (delta -6, but NOT a clean
' near miss -- localise_diff shows real structural misalignment, not just a few small gaps).
' VA 0x0057004C   KIND=Method, SIG=()i, class-table slot 0x3c.
' Revisited this pass -- see CHANGED THIS PASS below.
'
' RESOLVED (do not re-derive):
'  * Fields (object_model.json): x=+8, y=+12, message:$=+16, starttime=+20, delaytime=+24,
'    finishtime=+28, delaystart=+32, alfa:Float=+36, bmfnt:TBitmapFont=+40, img:TImage=+44,
'    imgScale:Float=+48, colour:$=+52, lbl:TLabel=+56.
'  * g_matchtime:Int (0x00C6EFD4) is the match/frame millisecond clock. NOT g_player_int50
'    -- see CHANGED THIS PASS, this was the actual bug.
'  * g_engine_int162:Int (0x00C6EFE4) is the backbuffer width -- well established.
'  * 0x00C6AFDC is a TList of TScreenMessage (Remove() called via slot 0x74). The corpus is
'    INCONSISTENT on its name across existing files (g_messages / g_screenMessages /
'    g_screenmessages / g_screenmessagelist all appear) -- picked g_screenmessages here,
'    which extracted/global_address_map.tsv confirms CERTAIN/unanimous across 4 bodies.
'  * 0x00C6F34C / 0x00C6F3B0 (TImage) already named g_kits_img1 / g_kits_img2 in
'    TScreen_Kits.Draw.bmx -- reused here as the SAME generic UI-bar images, now drawn as a
'    message backdrop via DrawImageRect (bar behind the text, tinted/scaled by alfa).
'  * Self.bmfnt (TBitmapFont) vtable: 0x4c=DrawText($,f,f,i)i, 0x54=GetTxtWidth($)i,
'    0x58=GetFontHeight()i. Self.lbl (TLabel) vtable: 0x44=Draw()i, 0x70=SetAlph(f)i.
'  * The un-decompiled call FUN_00505CEA (SetColourHex, sig ($)i, already recovered in
'    src/recovered_module/SetColourHex.bmx) shows ZERO visible arguments in Ghidra's C but
'    the annotation's byte-derived arg count is 1 -- this is Self.colour (the one field on
'    TScreenMessage never otherwise referenced in the body). SetColourHex(colour) is the only
'    field access that makes the arg count and the field list add up.
'  * `(**(code**)(*bmfnt+0x58))()` (GetFontHeight, Self-only) is called FOUR times total in
'    this function, at least two of which are DISCARDED (result unused) immediately before
'    ImageHeight(img) (also discarded) and before the real ImageWidth/GetFontHeight pair that
'    feeds the trailing DrawImage. This reads like dead/leftover code in the original (see
'    codegen-patterns.md law 3 -- reproduce faithfully, do not tidy) rather than a
'    misreading: the byte evidence (add esp,4 after EACH of the 4 calls) rules out folding
'    them into one real computation.
'
' CHANGED THIS PASS (w26 revisit):
'  1. WRONG GLOBAL NAME, the root cause of the 5.3% score. status/score showed our compiled
'     first comparison reading absolute address 0x00C9C644, not 0x00C6EFD4 -- and
'     `explain_global.py 0x00C9C644` resolves ZERO names, while `g_player_int50` is not
'     declared anywhere in src/assembled/nss5_assembled.bmx (the actual shared build the
'     scorer runs). The corpus's real, currently-declared name for 0x00C6EFD4 in THIS type
'     is `g_matchtime` -- confirmed by TWO byte-perfect siblings of TScreenMessage itself
'     (Create.bmx, CreateAlert.bmx, both `m.finishtime = g_matchtime + a3`) plus a third
'     byte-perfect sibling of a different type (TStats_Match.AddStat.bmx). `g_player_int50`
'     was evidently an unmerged/stale name that the shared assembler auto-allocates a fresh
'     (wrong) slot for instead of erroring. Renamed every occurrence to g_matchtime.
'  2. COMPARISON OPERAND ORDER, per codegen-patterns.md 10.1 ("Ghidra normalises operand
'     order; it is not byte-observable from the decompilation, read the raw cmp"). The
'     score report's own first-difference bytes decode as
'         mov eax,[edi+0x14]      ; eax = starttime
'         cmp [DAT_00c6efd4],eax  ; cmp now, starttime   (mem-first encoding, 0x39)
'         jge <continue>
'     i.e. the ORIGINAL's `cmp` places the global first, matching source text order
'     `now <compare> starttime`, not `starttime <compare> now` (our old phrasing). This is
'     exactly the pattern TStats_Match.AddStat.bmx documents for the SAME global:
'     `If g_matchtime > Self.lastdistancetime + 250` (cmp [g],ebx / jg) -- clock literally
'     written first. Applied consistently:
'       - guard 1 (was `If starttime > g_player_int50 Then Return 0`) -> now
'         `If g_matchtime < starttime Then Return 0` (global first, confirmed by the actual
'         disassembly bytes above).
'       - guard 2 (was `If finishtime < g_player_int50`) -> now `If g_matchtime > finishtime`
'         (same clock-first idiom; not independently byte-confirmed but structurally
'         identical to guard 1, same function, same developer).
'       - the dur*90.0 fade-out guard (was `dur*90.0 + Float(starttime) < Float(g_player_int50)`,
'         which the PREVIOUS pass flagged as an x87-push-order mystery costing 200+ bytes at
'         offset +202) -> now `Float(g_matchtime) > dur * 90.0 + Float(starttime)`. This is
'         very likely the actual fix for that mystery: the previous pass found `now` was
'         pushed onto the FPU stack BEFORE `starttime`/`dur*90.0`, which is exactly what
'         "now" being the textually-first operand would produce -- no compiler quirk needed,
'         just the wrong operand order in source. Applied to both occurrences of this guard
'         (the top-level alfa computation and its clone inside the tx slide-in/out block) for
'         internal consistency.
'       - the paired dur*10.0 fade-in guard was ALREADY global-first in both the decompile
'         and our source (`Float(g_player_int50) < dur*10.0 + ...`), so only the rename was
'         needed there; its "<=" clone inside the tx block was flipped to
'         `Float(g_matchtime) >= dur*10.0 + ...` for the same reasoning as the dur*90 guard.
'     The subtraction forms (`g_matchtime - starttime`, `finishtime - g_matchtime`) are NOT
'     touched -- operand order there is semantically load-bearing (a - b <> b - a) and
'     already matched the decompile's order.
'  Not independently re-verified against the oracle this pass (no compiler in the loop
'  available here) -- these are evidence-based corrections, not a confirmed byte match.
'
' STILL OPEN:
'   The prologue itself still differs in ways unexplained by the above: original reserves
'   `sub esp,0x14` (5 dwords) and caches Self in EDI; our last-scored build reserved
'   `sub esp,0x10` (4 dwords) and used ESI. Register/frame allocation in bcc is a
'   whole-function static pass over live ranges, not obviously tied to which Global name
'   resolves where, so this may or may not resolve once the corrections above are compiled
'   and rescored. If it persists, look for a missing/extra top-level Local (docs section
'   16.3: "read sub esp,N before writing anything") -- Ghidra names only two locals
'   (local_14=dur, local_10=tx) but the frame has room for ~5 dwords, so 3 more are spilled
'   somewhere the C names don't show.
'
' Globals (names ours; types load-bearing):
'!Global g_screenmessages:TList
'!Global g_matchtime:Int
'!Global g_engine_int162:Int
'!Global g_kits_img1:TImage
'!Global g_kits_img2:TImage

If g_matchtime < starttime Then Return 0
If g_matchtime > finishtime
	g_screenmessages.Remove(Self)
Else
	Local dur:Float = Float((finishtime - starttime) / 100)
	If dur = 0.0 Then dur = 1.0
	If Float(g_matchtime) < dur * 10.0 + Float(starttime)
		alfa = (Float(g_matchtime - starttime) / dur) / 10.0
	EndIf
	If Float(g_matchtime) > dur * 90.0 + Float(starttime)
		alfa = (Float(finishtime - g_matchtime) / dur) / 10.0
	EndIf
	ClampFloat(Varptr alfa, 0.0, 1.0)
	If lbl = Null
		If message.Length <> 0
			Local tx:Int = x
			Local tw:Int = bmfnt.GetTxtWidth(message)
			tx = tx - ((tw + (tw Shr 31 & 1)) Shr 1)
			If Float(g_matchtime) >= dur * 10.0 + Float(starttime)
				If Float(g_matchtime) > dur * 90.0 + Float(starttime)
					tx = Int((Float(g_engine_int162) - Float(g_engine_int162) * alfa) + Float(tx))
				EndIf
			Else
				tx = Int(Float(tx) - (1.0 - alfa) * Float(g_engine_int162))
			EndIf
			Local ty:Int = y
			Local th:Int = bmfnt.GetFontHeight()
			ty = ty - ((th + (th Shr 31 & 1)) Shr 1)
			SetColor(255, 255, 255)
			SetAlpha(alfa)
			Local th2:Int = bmfnt.GetFontHeight()
			Local hbar:Float = Float(th2 + 2) * alfa
			DrawImageRect(g_kits_img1, 0, Float(y - 5) - hbar * 0.5, Float(g_engine_int162), hbar, 0)
			DrawImageRect(g_kits_img2, 0, (Float(y - 5) - hbar * 0.5) - 2.0, Float(g_engine_int162), 4.0, 0)
			DrawImageRect(g_kits_img2, 0, (hbar * 0.5 + Float(y - 5)) - 2.0, Float(g_engine_int162), 4.0, 0)
			SetColourHex(colour)
			SetAlpha(alfa)
			bmfnt.DrawText(message, Float(tx), Float(ty), 1)
			If img <> Null
				bmfnt.GetFontHeight()
				ImageHeight(img)
				Local iw:Int = ImageWidth(img)
				Local ih:Int = bmfnt.GetFontHeight()
				DrawImage(img, Float(tx - iw), Float(ty - 1 + ((ih + (ih Shr 31 & 1)) Shr 1)), 0)
			EndIf
		EndIf
	Else
		lbl.SetAlph(alfa)
		lbl.Draw()
	EndIf
	SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
EndIf
Return 0

' localise_diff snapshot (PRE-rename, do not re-derive
' from this): orig 1119 / ours 1113, delta -6, 23 length-changing gaps + 25 substitutions.
' That pass mis-blamed x87 push order alone; w26 traced the real first divergence to the
' wrong Global (g_player_int50 vs g_matchtime, see CHANGED THIS PASS) plus the comparison
' operand order the wrong name masked. Not re-run against the oracle after this pass's
' edits -- rescore before trusting these numbers.
