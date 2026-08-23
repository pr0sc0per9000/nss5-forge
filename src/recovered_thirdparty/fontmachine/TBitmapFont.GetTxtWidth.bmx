' TBitmapFont.GetTxtWidth
' VA 0x00590B35   278 bytes   vtable slot 0x54   sig ($)i
' byte-identical vs NSS5.exe (278/278, mode=reloc, reloc_masked=5)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' ASSUMPTIONS
'  * a0 = the text to measure. Parameter name is not recoverable; a0.. as emitted.
'  * Mid/Asc are BRL.Retro (0x0059C7C0 _brl_retro_Mid, 0x004A7EE0 _bbStringAsc).
'    Asc returns -1 for an empty slice, which is what the `c >= 0` guard is for.
'  * `Kerning.PrivateData.HKF` is a direct field chain -- [Self+8][+8] then `fadd dword`
'    at [+8] -- NOT `Kerning.GetHKerning()`, which would be a call through slot 0x38.
'  * The accumulator is Float-valued: the int sum is spilled, `fild`ed, HKF added, then
'    converted back by _bbFloatToInt (0x005B9690). That whole sequence is the compiler's
'    doing; the source is one assignment whose right-hand side is a Float.
'
' The two tail statements MUST be written as separate `:-` / `:+` compound assignments.
' As one expression (`w = w - .Charwidth + .DrawWidth`) bcc materialises w in eax and
' stores it back, +4 bytes; `:-`/`:+` operate on w's register in place, which is what
' the original does.
'
' BUG (original): `last` starts at 0 and is only ever assigned inside the loop, so a
' string whose every character is missing from the font still runs the tail block against
' Face[0]. Preserved.

	Method GetTxtWidth:Int(a0:String)
		Local w:Int = 0
		Local last:Int = 0
		For Local i:Int = 1 To a0.Length
			Local c:Int = Asc(Mid(a0, i, 1))
			If c >= 0 And c < PrivateData.Face.Length
				If PrivateData.Face[c] <> Null
					last = c
					w = (w + PrivateData.Face[c].Charwidth) + Kerning.PrivateData.HKF
				End If
			End If
		Next
		If last >= 0 And last < PrivateData.Face.Length
			If PrivateData.Face[last] <> Null
				w :- PrivateData.Face[last].Charwidth
				w :+ PrivateData.Face[last].DrawWidth
			End If
		End If
		Return w
	End Method
