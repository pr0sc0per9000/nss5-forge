' TBitmapFont.DrawTextMaxWidth
' VA 0x00590842   755 bytes   vtable slot 0x50   sig ($,f,f,d,i)i
' NEAR MISS -- NOT byte-identical. harness.try_method (NSS5_NO_LEARN=1, worker 417):
'   status=MISMATCH, our_len=755 (= original), mode=reloc, matched=661/755.
' THIRD-PARTY MODULE (fontmachine). It is here and not in src/recovered_thirdparty/
' because it did not reach MATCH; see RULES 5.2. Do NOT copy the "byte-identical"
' marker onto it.
'
' THE ENTIRE RESIDUAL IS SIX BYTES SCHEDULED 28 BYTES EARLY, and nothing else. At the
' instruction level every other byte of the 755 agrees. Normalised diff (O = NSS5.exe,
' U = ours), which is the whole of it:
'
'     ... 79 instructions equal (orig +0..+238) ...
'     U+242  dd45dc  fld  qword [ebp-0x24]      <- ours emits the w->temp copy HERE
'     U+245  dd5de8  fstp qword [ebp-0x18]
'     ... 10 instructions equal (orig +242..+268) ...   <- the two products
'     O+270  dd45dc  fld  qword [ebp-0x24]      <- the original emits it HERE
'     O+273  dd5de8  fstp qword [ebp-0x18]
'     ... 171 instructions equal (orig +276..+754) ...
'
' Both spellings are the same five-instruction idiom for a Double `+` whose left operand
' is a memory Double: copy the left operand into the expression temp, then
' `fld temp / faddp / fstp temp`. The two compilers differ only in WHEN the copy is
' emitted relative to the right operand's evaluation, and the difference is driven by the
' explicit numeric conversion discussed below, not by the statement's shape:
'   * with no conversion in the right subtree, our bcc emits the copy AFTER the right
'     operand -- i.e. exactly where NSS5.exe has it (measured: the cast-free variant of
'     this body puts `fld [ebp-0x24] / fstp [ebp-0x18]` at +270, matching);
'   * with a conversion in the right subtree it hoists the copy ahead of it.
' NSS5.exe needs the conversion (see below) AND the late copy at the same time, and no
' spelling reached in this pass produces both. Twenty candidate spellings of the condition
' were measured; every "w on the left" form scores 661/755 and every "w on the right" form
' scores 648/755 (bcc folds the accumulator into `fadd qword [ebp-0x24]` when it is the
' right operand, which the original does not do -- so w IS the left operand).
'
' WHY Double(...) IS WRITTEN ON THE TWO CHARACTER-METRIC PRODUCTS. It is the only spelling
' found that reproduces their exact bytes. `Int * Float` folds to `fild / fmul dword [m]`
' (6 bytes); NSS5.exe emits `fild / fld dword [ebp-4] / fmulp st(1)` (8 bytes) at all
' three character-metric sites, and the folded `fmul dword [ebp-4]` at the two kerning
' sites in the same expressions. Without the conversion the body compiles to 749 bytes --
' exactly 3 x 2 short -- so the non-folding is real and is a property of the original, not
' a guess. The conversion is UNCERTAIN as source text: what is certain from the bytes is
' that the character-metric product is Double-typed and the kerning product is not.
' Contrast `GetFontHeight() * sy`, also Int * Float, which DOES fold in NSS5.exe
' (`fild [ebp-0x34] / fmul dword [ebp-8]`) because it feeds the Float y, not the Double w.
'
' FRAME LAYOUT, read off NSS5.exe and reproduced exactly by the declaration order below
' (all 79 prologue instructions match, so this is settled, not assumed):
'   [ebp-4]    sx:Float          [ebp-0x1c] line:String
'   [ebp-8]    sy:Float          [ebp-0x24] w:Double     (running line width)
'   [ebp-0x10] Double temp       [ebp-0x28] y:Float      (running baseline, from a2)
'   [ebp-0x18] Double temp       [ebp-0x2c] For-limit    [ebp-0x30] stop:Int
'   [ebp-0x34] Int->Float conversion temp;  edi = i,  ebx = Self,  esi = the TBitMapChar
' Slots are NOT assigned in declaration order -- the order below is the one that
' reproduces both the slots and the init sequence, and was found by measurement.
'
' RESOLVED CALL TARGETS (extracted/brl_functions.tsv, runtime_helpers.tsv):
'   0x005AE0D3 _brl_max2d_GetScale(x:Float Var, y:Float Var)   0x005B13E2 GraphicsHeight
'   0x0059C7C0 _brl_retro_Mid   0x004A7EE0 _bbStringAsc   0x004A7C20 _bbStringConcat
'   0x004A6A30 _bbStringCompare   0x004A7FE0 _bbFloatAbs (fld qword [esp+4]; fabs)
'   vtable +0x4C = DrawText($,f,f,i)i, +0x58 = GetFontHeight()i, both called on Self.
'
' FIELD OFFSETS confirmed against this body's own disassembly:
'   TBitmapFont.Kerning +0x08, .PrivateData +0x24;  TPrivateBitmapFont.Face +0x10;
'   TFontKerning.PrivateData +0x08;  TPrivateFontKerning.HKF +0x08, .VKF +0x0C;
'   TBitMapChar.DrawWidth +0x10, .Charwidth +0x18.
' The width TEST uses DrawWidth (ink) while the accumulator uses Charwidth (advance) --
' that asymmetry is read from the two distinct displacements, not inferred.
'
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted.
' a3 is the max width and is a Double (`fld qword [ebp+0x18]`), not a Float.
'
' BEHAVIOUR (original, preserved): characters are appended to `line` until the next one
' would overflow a3 - Abs(sx), then `line` is drawn and a new one started; Asc = 10
' forces a break; the `If line <> ""` guard means a forced break on an already-empty line
' does not advance the baseline, but the Asc=10 path advances it unconditionally.
' `stop` suppresses the final flush once the baseline has passed GraphicsHeight().
'
	Method DrawTextMaxWidth:Int(a0:String, a1:Float, a2:Float, a3:Double, a4:Int)
		Local w:Double = 0
		Local line:String = ""
		Local y:Float = a2
		Local sx:Float
		Local sy:Float
		Local stop:Int = 0
		GetScale(sx, sy)
		For Local i:Int = 1 To a0.Length
			If Asc(Mid(a0, i, 1)) <> 10 And Asc(Mid(a0, i, 1)) < PrivateData.Face.Length
				If PrivateData.Face[Asc(Mid(a0, i, 1))] <> Null
					Local c:TBitMapChar = PrivateData.Face[Asc(Mid(a0, i, 1))]
					If w + (Double(c.DrawWidth) * sx + Kerning.PrivateData.HKF * sx) < a3 - Abs(sx)
						line = line + Mid(a0, i, 1)
						w :+ Double(c.Charwidth) * sx + Kerning.PrivateData.HKF * sx
					Else
						DrawText(line, a1, y, a4)
						If line <> ""
							y :+ GetFontHeight() * sy + Kerning.PrivateData.VKF * sy
						End If
						line = Mid(a0, i, 1)
						w = Double(c.Charwidth) * sx + Kerning.PrivateData.HKF * sx
					End If
				End If
			Else
				DrawText(line, a1, y, a4)
				y :+ GetFontHeight() * sy + Kerning.PrivateData.VKF * sy
				line = ""
				w = 0
			End If
			If y > GraphicsHeight()
				stop = 1
				Exit
			End If
		Next
		If line <> "" And stop = 0
			DrawText(line, a1, y, a4)
		End If
		Return 0
	End Method
