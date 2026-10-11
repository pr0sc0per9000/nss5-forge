' TBitmapFont.DrawTextMaxWidth
' VA 0x00590842   755 bytes   vtable slot 0x50   sig ($,f,f,d,i)i
' byte-identical vs NSS5.exe (755/755, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (fontmachine).
'
' THE WIDTH TEST READS A LOCAL, cw. For a Double `+`, bcc copies the left operand into the
' expression temp before it evaluates the right one (_src/codegen/cgframe_x86.cpp:437-440,
' genBop), so `w + (product)` written as one expression emits `fld [w] / fstp [temp]` ahead
' of the products. NSS5.exe has the products first, which is what a register Local assigned
' in the statement before gives. `cw` costs no bytes: the product's register coalesces into
' it. Double(...) on the character-metric product is still needed: without it `Int * Float`
' folds to `fmul dword [m]` and the body is 749 bytes, 3 x 2 short.
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
					Local cw:Double = Double(c.DrawWidth) * sx + Kerning.PrivateData.HKF * sx
					If w + cw < a3 - Abs(sx)
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
