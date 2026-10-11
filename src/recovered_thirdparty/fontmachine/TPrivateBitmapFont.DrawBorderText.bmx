' TPrivateBitmapFont.DrawBorderText
' VA 0x00591917   1195 bytes   vtable slot 0x34   sig ($,f,f,:TBitmapFont)i
' byte-identical vs NSS5.exe (1195/1195, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (fontmachine). Needs the bcc scripts/setup.py builds (extern/bcc).
'
' Three values tie exactly on spill cost, and the original breaks that tie its own way.
' The patched bcc gives this function the `mirror` rule, which reproduces it
' (extern/bcc/README.md, docs/reference/spill-tie-x87-precision.md).
'
' The same walk as DrawShadowText over the Border layer, plus the PhisicalPixelRounding
' path: when the font asks for it the glyph is placed on whole DEVICE pixels by
' temporarily dropping the virtual resolution, rounding both the scale factors and the
' destination, drawing, then putting resolution and scale back.
'
' ASSUMPTIONS AND SHAPE NOTES (each of these changes the bytes):
'  * Fn_00592B87 is the round-half-away-from-zero helper; see its own file.
'  * The rounding path's arithmetic is DOUBLE and the casts have to be written out. Both
'    operands of `Fn_00592B87(...) / Image.width` are Int, so without `Double(...)` bcc
'    emits `idiv` where the original has fild/fild/fdivp; and `Double(sx) * GraphicsWidth()`
'    must be Double at the multiply or the spill across the call is a 4-byte `fstp dword`
'    instead of the original's 8-byte `fstp qword`. `Double(x) * y` and `x / Double(y)`
'    are interchangeable spellings -- the bytes cannot say which side the original cast.
'  * `a1 = startx` is an explicit statement here and the recursive call passes a1;
'    DrawShadowText passes the saved margin directly instead. The difference is visible.
'  * act.CurrentScaleY is assigned BEFORE act.CurrentScaleX (offsets 0x18 then 0x14).
'    DrawFaceText does it the other way round.
'
' BUG (original): as in DrawShadowText, the FX path guards on `Face[c]` and draws
' `Border[c].Image`. Preserved.

	Method DrawBorderText:Int(a0:String, a1:Float, a2:Float, a3:TBitmapFont)
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
					a1 = startx
					a2 = a2 + Face[32].DrawHeight * sy + a3.Kerning.PrivateData.VKF * sy
					DrawBorderText(Mid(a0, i + 1, -1), a1, a2, a3)
					Return 0
				End If
				If Border[c] <> Null
					If Border[c].Image <> Null
						Local dead:TDrawingPoint = New TDrawingPoint
						Local p:TDrawingPoint = New TDrawingPoint
						p.X = a1
						p.Y = a2
						Local pt:TDrawingPoint = Fn_00592A37(rot, p, origin)
						If hasfx = 0
							If a3.PhisicalPixelRounding = 0
								DrawImage(Border[c].Image, pt.X, pt.Y, 0)
							Else
								Local vrw:Float = VirtualResolutionWidth()
								Local vrh:Float = VirtualResolutionHeight()
								Local sxpos:Float = pt.X * (GraphicsWidth() / vrw)
								Local sypos:Float = pt.Y * (GraphicsHeight() / vrh)
								SetVirtualResolution(GraphicsWidth(), GraphicsHeight())
								Local xscale:Double = Double(sx) * GraphicsWidth() / vrw
								Local yscale:Double = Double(sy) * GraphicsHeight() / vrh
								xscale = Double(Fn_00592B87(xscale * Border[c].Image.width)) / Border[c].Image.width
								yscale = Double(Fn_00592B87(yscale * Border[c].Image.height)) / Border[c].Image.height
								SetScale(xscale, yscale)
								DrawImage(Border[c].Image, Fn_00592B87(sxpos), Fn_00592B87(sypos), 0)
								SetVirtualResolution(vrw, vrh)
								SetScale(sx, sy)
							End If
						Else
							Local act:TDrawCharAction = New TDrawCharAction
							act.Char = c
							act.font = a3
							act.Handled = 0
							act.Status = 2
							act.X = pt.X
							act.Y = pt.Y
							act.CurrentScaleY = RenderStatus.ScaleY
							act.CurrentScaleX = RenderStatus.ScaleX
							Local fx:iTextRendererFXBase = a3.RenderFX
							While fx <> Null
								fx.DrawBorderChar(act)
								fx = fx.ChainFX
							Wend
							c = act.Char
							If act.Handled = 0
								If Face[c] <> Null
									DrawImage(Border[c].Image, act.X, act.Y, 0)
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
