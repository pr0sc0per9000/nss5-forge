' TPrivateBitmapFont.DrawShadowText
' VA 0x00591DC2   666 bytes   vtable slot 0x38   sig ($,f,f,:TBitmapFont)i
' byte-identical vs NSS5.exe (666/666, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (fontmachine). Needs the bcc scripts/setup.py builds (extern/bcc).
'
' Three values tie exactly on spill cost, and the original breaks that tie its own way.
' The patched bcc gives this function the `mirror` rule, which reproduces it
' (extern/bcc/README.md, docs/reference/spill-tie-x87-precision.md).
'
' WHAT IT DOES. Walks the string a character at a time and blits Shadow[c].Image at the
' running pen position, rotated about the line start by RenderStatus.Rotation. Character
' 10 is a hard line break: it advances y by one line and TAIL-RECURSES on the remainder
' from the saved left margin. Unlike its Border and Face siblings it has no
' PhisicalPixelRounding path and never touches SetScale.
'
' ASSUMPTIONS AND SHAPE NOTES (each of these changes the bytes):
'  * a0=text, a1=x, a2=y, a3=the owning TBitmapFont. a1 and a2 are the running pen and
'    are written through as parameters; only the line-start x is copied to a Local.
'  * The DOUBLE `New TDrawingPoint` is the original's. The first result is discarded --
'    a dead Local -- and bcc does not eliminate it because bbObjectNew has side effects.
'    Written as one New the body is 13 bytes short.
'  * `a2 = a2 + ... + ...` in the newline branch but `a1 :+ ... + ...` at the end. The
'    two are not interchangeable: `:+` computes the whole right side first and then adds,
'    the plain form loads the accumulator first (codegen-patterns 16.1), and the original
'    uses one of each.
'  * The Shadow[c] / Shadow[c].Image guards are NESTED Ifs, not an `And` chain. An `And`
'    materialises its operands through setcc/movzx; only `c >= 0 And c < Face.Length`
'    does that here.
'
' BUG (original): the FX path re-reads `act.Char` and then tests `Face[c] <> Null` before
' drawing `Shadow[c].Image` -- the wrong array for the guard. Preserved.

	Method DrawShadowText:Int(a0:String, a1:Float, a2:Float, a3:TBitmapFont)
		Local startx:Float = a1
		Local sx:Float = RenderStatus.ScaleX
		Local sy:Float = RenderStatus.ScaleY
		Local origin:TDrawingPoint = Fn_00592A13(a1, a2)
		Local rot:Float = RenderStatus.Rotation
		Local hasfx:Int = a3.RenderFX <> Null
		For Local i:Int = 1 To a0.Length
			Local c:Int = Asc(Mid(a0, i, 1))
			If c >= 0 And c < Face.Length
				If c = 10
					a2 = a2 + Face[32].DrawHeight * sy + a3.Kerning.PrivateData.VKF * sy
					DrawShadowText(Mid(a0, i + 1, -1), startx, a2, a3)
					Return 0
				End If
				If Shadow[c] <> Null
					If Shadow[c].Image <> Null
						Local dead:TDrawingPoint = New TDrawingPoint
						Local p:TDrawingPoint = New TDrawingPoint
						p.X = a1
						p.Y = a2
						Local pt:TDrawingPoint = Fn_00592A37(rot, p, origin)
						If hasfx = 0
							DrawImage(Shadow[c].Image, pt.X, pt.Y, 0)
						Else
							Local act:TDrawCharAction = New TDrawCharAction
							act.Char = c
							act.font = a3
							act.Handled = 0
							act.Status = 4
							act.X = pt.X
							act.Y = pt.Y
							Local fx:iTextRendererFXBase = a3.RenderFX
							While fx <> Null
								fx.DrawShadowChar(act)
								fx = fx.ChainFX
							Wend
							c = act.Char
							If act.Handled = 0
								If Face[c] <> Null
									DrawImage(Shadow[c].Image, act.X, act.Y, 0)
								End If
							End If
						End If
						If Face[c] <> Null
							a1 :+ Face[c].Charwidth * sx + a3.Kerning.PrivateData.HKF * sx
						End If
					End If
				End If
			End If
		Next
	End Method
