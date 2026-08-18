' TileDrawFrame -- module-level Function (no Type, no reflection record; name is OURS)
' VA 0x005066AB   946 bytes   sig (:TImage,f,f,i)i
' byte-identical vs NSS5.exe (946/946, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=23) -- confirmed under NSS5_NO_LEARN=1 (all 9 distinct
' callees below were already named in extracted/runtime_helpers.tsv /
' extracted/brl_functions*.tsv from earlier passes, so nothing here is self-taught).
'
' Tiles `a0` (an TImage) across the current 2D viewport, offset by the world-space
' point (a1,a2), forwarding `a3` as the DrawImage frame index. Called 3x from
' TPitch.Render (0x004E6625) to lay down the grass/pitch-condition base texture.
' Algorithm-identical to BRL.Max2D's own TileImage (max2d.mod/max2d.bmx:418,
' Int-typed there); this is the game's own Float/world-coordinate, per-frame rewrite.
'
' An earlier candidate (src/recovered_unverified/TileDrawFrame.bmx, replaced by this file)
' reached 869/946 (delta -77) and correctly named all 9 callees, but got the ALGORITHM
' subtly wrong in three ways that a full manual read of NSS5.exe's own disassembly (all 946
' bytes, not just the gap windows) resolves:
'   1. `ih`/`iw` (ImageHeight/ImageWidth) are FLOAT locals, not Int -- the original
'      converts the call's Int result to float with `fild` IMMEDIATELY after the call,
'      before Abs(sx)/Abs(sy) is even evaluated, not at the multiply.
'   2. `rr`/`bb` (vx+vw, vy+vh) are likewise FLOAT, converted the same way, not Int.
'   3. The tile-fraction terms are PRECOMPUTED as `px - Floor(px)` / `py - Floor(py)`
'      (the previous candidate stored bare `Floor(px)`/`Floor(py)` and deferred the
'      subtraction to the DrawImage call site -- same VALUE, different bytes). This is
'      also why the original's frame is 6 dword-equivalents (24 bytes) larger than the
'      old candidate's: `px`/`py` each get widened to a genuine 8-byte Double temp
'      (`fstp qword`) and stashed in memory BEFORE the call to Floor(), because the
'      value must survive the call and bcc conservatively spills anything x87 that has
'      to live across a call. Read directly off the disassembly (fsubrp st(1) computes
'      ST0-ST1 = px_double - FloorResult, i.e. the REVERSED subtract, confirming the
'      operand order): `harness.disasm_original(0x005066AB, 946, after=1000)`.
' The `d`/`d2` terms (`Floor(px)-tx`, `Floor(py)-ty`) were already correct in the old
' candidate and needed no change -- there bcc reloads `tx`/`ty` as plain single-precision
' AFTER the call instead of pre-widening, because (unlike px/py) tx/ty are not consumed
' as the call's own argument, so nothing forces an early spill.
'
' The solo-relational If/Else NEGATION+SWAP rule (codegen-patterns.md sec. 21) also
' applies at both `d`/`d2` sign tests: the original's setcc is
' `setb` (checks `< 0`, TRUE branch taken via a forward jne), which is produced by
' writing the NEGATED condition with swapped Then/Else content -- `If d >= 0.0 Then
' (mod-only case) Else (wrap-around case)` -- not the direct `If d < 0.0 Then (wrap)
' Else (mod-only)` the previous candidate had.
'
' Two Float constants, both read directly from the exe (not guessed): 0x00C7BBD4 and
' 0x00C7BBD8 are both 1.0 (the one-tile viewport overdraw margin added to tx/ty).
'
' CALLEES (all named on both sides; none learned this run):
'   BRL.Max2D    GetScale, GetViewport, GetOrigin, GetHandle, ImageHeight, ImageWidth,
'                SetOrigin (called twice: force to 0,0 before tiling; restore after),
'                DrawImage
'   C runtime    _bbFloor (0x004A2000, called 4x), _bbFloatAbs (0x004A7FE0, 2x),
'                _bbFloatMod (0x004A8030, 4x) -- all in extracted/runtime_helpers.tsv
' None are module Globals; a0-a3 are the only inputs.
	Function TileDrawFrame:Int(a0:TImage, a1:Float, a2:Float, a3:Int)
		Local sx:Float, sy:Float
		GetScale(sx, sy)
		Local vx:Int, vy:Int, vw:Int, vh:Int
		GetViewport(vx, vy, vw, vh)
		Local ox:Float, oy:Float
		GetOrigin(ox, oy)
		Local hx:Float, hy:Float
		GetHandle(hx, hy)
		Local ih:Float = ImageHeight(a0)
		Local iw:Float = ImageWidth(a0)
		Local cw:Float = iw * Abs(sx)
		Local ch:Float = ih * Abs(sy)
		Local tx:Float = (vx - cw) + 1.0
		Local ty:Float = (vy - ch) + 1.0
		ox = ox Mod cw
		oy = oy Mod ch
		Local px:Float = (a1 + ox) - hx
		Local py:Float = (a2 + oy) - hy
		Local fx:Float = px - Floor(px)
		Local fy:Float = py - Floor(py)
		Local d:Float = Floor(px) - tx
		Local d2:Float = Floor(py) - ty
		If d >= 0.0
			d = (d Mod cw) + tx
		Else
			d = (cw - (-d Mod cw)) + tx
		EndIf
		If d2 >= 0.0
			d2 = (d2 Mod ch) + ty
		Else
			d2 = (ch - (-d2 Mod ch)) + ty
		EndIf
		Local rr:Float = vx + vw
		Local bb:Float = vy + vh
		SetOrigin 0, 0
		Local iy:Float = d2
		While iy < bb + ch
			Local ix:Float = d
			While ix < rr + cw
				DrawImage a0, ix + fx, iy + fy, a3
				ix = ix + cw
			Wend
			iy = iy + ch
		Wend
		SetOrigin ox, oy
		Return 0
	End Function
