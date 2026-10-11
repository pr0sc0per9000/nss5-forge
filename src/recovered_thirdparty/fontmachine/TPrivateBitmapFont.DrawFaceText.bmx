' TPrivateBitmapFont.DrawFaceText
' VA 0x00591383   1428 bytes   vtable slot 0x30   sig ($,f,f,:TBitmapFont)i
' byte-identical vs NSS5.exe (1428/1428, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (fontmachine). Needs the bcc scripts/setup.py builds (extern/bcc).
'
' Three values tie exactly on spill cost, and the original breaks that tie its own way.
' The patched bcc gives this function the `le` rule, which reproduces it
' (extern/bcc/README.md, docs/reference/spill-tie-x87-precision.md).
' Its two calls to 0x004A7990 need that address named _bbStringFromDouble
' (scripts/helper_map.py BRL_ALIAS_ADDITIONS).
'
' The glyph face itself -- the layer every piece of text in the game actually shows.
' Same structure as its Border sibling, with three differences that are all in the bytes:
'
'  * The pen is THREE Locals (curx, cury, startx), not the parameters. a1 and a2 are read
'    at entry and never written; bcc keeps both on the x87 stack across the three `fst`s,
'    which is the fxch/fst/fxch/fst/fxch/fst opening.
'  * The screen-position scaling is Double where DrawBorderText's is Float:
'    `pt.X * (Double(GraphicsWidth()) / vrw)`. Put the cast on pt.X instead and the
'    division keeps a 3-byte `fdiv dword [vrw]` memory operand, 4 bytes short.
'  * There is a leftover DEBUG statement: for the letter m (109) it Prints the rounded
'    destination, the scaled glyph width and the x scale. It is live in the retail build
'    and fires on the PhisicalPixelRounding path only. Preserved, literals and all.
'
' BUG (original): the bounds test is `c <= Face.Length`, not `<`, so a codepoint exactly
' equal to the array length indexes one past the end. Preserved.

	Method DrawFaceText:Int(a0:String, a1:Float, a2:Float, a3:TBitmapFont)
		Local curx:Float = a1
		Local cury:Float = a2
		Local startx:Float = a1
		Local sx:Float = RenderStatus.ScaleX
		Local sy:Float = RenderStatus.ScaleY
		Local origin:TDrawingPoint = Fn_00592A13(a1, a2)
		Local rot:Float = RenderStatus.Rotation
		Local hasfx:Int = a3.RenderFX <> Null
		For Local i:Int = 1 To a0.Length
			Local c:Int = Asc(Mid(a0, i, 1))
			If c >= 0 And c <= Face.Length
				If c = 10
					cury = cury + Face[32].DrawHeight * sy + a3.Kerning.PrivateData.VKF * sy
					DrawFaceText(Mid(a0, i + 1, -1), startx, cury, a3)
					Return 0
				End If
				If Face[c] <> Null
					If Face[c].Image <> Null
						Local dead:TDrawingPoint = New TDrawingPoint
						Local p:TDrawingPoint = New TDrawingPoint
						p.X = curx
						p.Y = cury
						Local pt:TDrawingPoint = Fn_00592A37(rot, p, origin)
						If hasfx = 0
							If a3.PhisicalPixelRounding = 0
								DrawImage(Face[c].Image, pt.X, pt.Y, 0)
							Else
								Local vrw:Float = VirtualResolutionWidth()
								Local vrh:Float = VirtualResolutionHeight()
								Local sxpos:Float = pt.X * (Double(GraphicsWidth()) / vrw)
								Local sypos:Float = pt.Y * (Double(GraphicsHeight()) / vrh)
								SetVirtualResolution(GraphicsWidth(), GraphicsHeight())
								Local xscale:Double = Double(sx) * GraphicsWidth() / vrw
								Local yscale:Double = Double(sy) * GraphicsHeight() / vrh
								xscale = Double(Fn_00592B87(xscale * Face[c].Image.width)) / Face[c].Image.width
								yscale = Double(Fn_00592B87(yscale * Face[c].Image.height)) / Face[c].Image.height
								SetScale(xscale, yscale)
								DrawImage(Face[c].Image, Fn_00592B87(sxpos), Fn_00592B87(sypos), 0)
								If c = 109
									Print "(" + Fn_00592B87(sxpos) + ", " + Fn_00592B87(sypos) + ")" + Face[c].Image.width * xscale + "  -  " + xscale
								End If
								SetVirtualResolution(vrw, vrh)
								SetScale(sx, sy)
							End If
						Else
							Local act:TDrawCharAction = New TDrawCharAction
							act.Char = c
							act.font = a3
							act.Handled = 0
							act.Status = 1
							act.X = pt.X
							act.Y = pt.Y
							act.CurrentScaleX = RenderStatus.ScaleX
							act.CurrentScaleY = RenderStatus.ScaleY
							Local fx:iTextRendererFXBase = a3.RenderFX
							While fx <> Null
								fx.DrawFaceChar(act)
								fx = fx.ChainFX
							Wend
							c = act.Char
							If act.Handled = 0
								If Face[c] <> Null
									DrawImage(Face[c].Image, act.X, act.Y, 0)
								End If
							End If
						End If
						If Face[c] <> Null
							curx :+ Face[c].Charwidth * sx + a3.Kerning.PrivateData.HKF * sx
						End If
					End If
				End If
			End If
		Next
	End Method
