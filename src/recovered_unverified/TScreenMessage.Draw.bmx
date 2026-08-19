' TScreenMessage.Draw -- NOT VERIFIED. orig 1119 bytes, this body 1120: localise_diff
' resolves the whole 1-byte gap to two register-allocation/scheduling differences, neither
' a comparison, a branch sense, a call target, or a wrong constant.
'  (a) The original caches Self in EDI and keeps the y-based draw position (ty) live in ESI
'      across every later call in the block; `sub esp,0x14` (5 scratch dwords). This build
'      caches Self in ESI instead and reloads ty from its own stack slot/field when needed;
'      `sub esp,0x10` (4 dwords). Every plain register-name substitution localise_diff
'      reports (EDI/ESI, and the paired [ebp-0x14]/[ebp-0x10] scratch-slot offsets) reduces
'      to this one difference.
'  (b) The final `DrawImage(img, Float(tx - iw), Float(ty - 1 + ih / 2), 0)` call's two
'      Float sub-expression arguments: the original fully computes and converts the
'      earlier-declared x argument to a cached Float temp before issuing any push for this
'      call, then pushes all four arguments in reverse-declaration order in one burst. This
'      build's toolchain evaluates and pushes each argument in reverse-declaration order as
'      it goes, which needs one extra register copy (an anonymous compiler temp with no
'      source handle) and computes the two Float sub-expressions in the opposite order. The
'      original also leaves a single orphan `cdq` (1 byte) right after the second of the two
'      discarded `bmfnt.GetFontHeight()` / `ImageHeight(img)` calls that precede this block,
'      with no completing and/add/sar afterward. Tested and ruled out as source-reachable: a
'      bare `expr / 2` statement does not compile ("Types 'TImage' and 'Int' are unrelated"),
'      and a stored `Local x:Int = expr / 2` needs the complete 4-instruction idiom, which
'      overshoots the byte count observed here by 6 bytes. Attributed to the original
'      compiler's own optimizer leaving a dead-code fragment behind, not to a source
'      construct; adding a Local to force the original's evaluation order was tried and
'      makes the whole-function match measurably worse (delta swings from +1 to -18 bytes),
'      the same whole-function register-allocator repack signature already seen in (a).
' VA 0x0057004C   1119 bytes   vtable slot 0x3c   sig ()i
'
' RESOLVED (do not re-derive):
'  * Fields (object_model.json): x=+8, y=+12, message:$=+16, starttime=+20, delaytime=+24,
'    finishtime=+28, delaystart=+32, alfa:Float=+36, bmfnt:TBitmapFont=+40, img:TImage=+44,
'    imgScale:Float=+48, colour:$=+52, lbl:TLabel=+56.
'  * g_matchtime:Int (0x00C6EFD4) is the match/frame millisecond clock. Every comparison
'    against it places g_matchtime first (`cmp [g_matchtime],eax`), matching source text
'    order `g_matchtime <compare> field`; the subtraction forms (`g_matchtime - starttime`,
'    `finishtime - g_matchtime`) keep their own order since a - b <> b - a.
'  * g_engine_int162:Int (0x00C6EFE4) is the backbuffer width.
'  * 0x00C6AFDC is a TList of TScreenMessage (Remove() called via slot 0x74), named
'    g_screenmessages -- extracted/global_address_map.tsv confirms this name unanimous
'    across four bodies.
'  * 0x00C6F34C / 0x00C6F3B0 (TImage) are named g_kits_img1 / g_kits_img2 in
'    TScreen_Kits.Draw.bmx and reused here as the same generic UI-bar images, drawn as a
'    message backdrop via DrawImageRect (bar behind the text, tinted/scaled by alfa).
'  * Self.bmfnt (TBitmapFont) vtable: 0x4c=DrawText($,f,f,i)i, 0x54=GetTxtWidth($)i,
'    0x58=GetFontHeight()i. Self.lbl (TLabel) vtable: 0x44=Draw()i, 0x70=SetAlph(f)i.
'  * The un-decompiled call FUN_00505CEA (SetColourHex, sig ($)i, recovered in
'    src/recovered_module/SetColourHex.bmx) takes Self.colour, the one field on
'    TScreenMessage never otherwise referenced in the body.
'  * `(**(code**)(*bmfnt+0x58))()` (GetFontHeight, Self-only) is called four times total.
'    Two of the calls (a bare `bmfnt.GetFontHeight()` and `ImageHeight(img)` right before
'    the Local iw/ih pair) discard their result -- dead/leftover code in the original (law
'    3: reproduce faithfully, do not tidy), confirmed by an `add esp,4` after each of the
'    four calls, which rules out folding them into one real computation.
'  * The first SetAlpha call in the message-bar block passes `alfa * 0.75`, not bare alfa:
'    the disassembly computes the product on the FPU (`fld`/`fmul 0.75`/`fstp`) before the
'    call, where the second SetAlpha call just pushes the field directly with no FPU work.
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
	Return 0
Else
	Local dur:Float = Float((finishtime - starttime) / 100)
	If dur = 0.0 Then dur = 1.0
	If Float(g_matchtime) < Float(starttime) + dur * 10.0
		alfa = (Float(g_matchtime - starttime) / dur) / 10.0
	EndIf
	If Float(g_matchtime) > Float(starttime) + dur * 90.0
		alfa = (Float(finishtime - g_matchtime) / dur) / 10.0
	EndIf
	ClampFloat(Varptr alfa, 0.0, 1.0)
	If lbl <> Null
		lbl.SetAlph(alfa)
		lbl.Draw()
	Else
		If message.Length <> 0
			Local tx:Int = x - bmfnt.GetTxtWidth(message) / 2
			If Float(g_matchtime) < Float(starttime) + dur * 10.0
				tx = Int(Float(tx) - Float(g_engine_int162) * (1.0 - alfa))
			Else
				If Float(g_matchtime) > Float(starttime) + dur * 90.0
					tx = Int(Float(tx) + (Float(g_engine_int162) - Float(g_engine_int162) * alfa))
				EndIf
			EndIf
			Local ty:Int = y - bmfnt.GetFontHeight() / 2
			SetColor(255, 255, 255)
			SetAlpha(alfa * 0.75)
			Local th2:Int = bmfnt.GetFontHeight()
			Local hbar:Float = Float(th2 + 2) * alfa
			DrawImageRect(g_kits_img1, 0, Float(y - 5) - hbar * 0.5, Float(g_engine_int162), hbar, 0)
			DrawImageRect(g_kits_img2, 0, (Float(y - 5) - hbar * 0.5) - 2.0, Float(g_engine_int162), 4.0, 0)
			DrawImageRect(g_kits_img2, 0, (Float(y - 5) + hbar * 0.5) - 2.0, Float(g_engine_int162), 4.0, 0)
			SetColourHex(colour)
			SetAlpha(alfa)
			bmfnt.DrawText(message, Float(tx), Float(ty), 1)
			If img <> Null
				bmfnt.GetFontHeight()
				ImageHeight(img)
				Local iw:Int = ImageWidth(img)
				Local ih:Int = bmfnt.GetFontHeight()
				DrawImage(img, Float(tx - iw), Float(ty - 1 + ih / 2), 0)
			EndIf
		EndIf
	EndIf
	SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
EndIf
Return 0
