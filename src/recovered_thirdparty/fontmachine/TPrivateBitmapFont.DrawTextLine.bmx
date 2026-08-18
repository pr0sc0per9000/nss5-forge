' TPrivateBitmapFont.DrawTextLine
' VA 0x0059205C   431 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ($,f,f,i,:TBitmapFont)i, slot 0x3c
' ASSUMPTIONS
'  * No module Globals are touched.
'  * a0=text, a1=x, a2=y, a3=blend-enable flag, a4=the owning TBitmapFont.
'  * GetBlend/GetScale/GetRotation/SetBlend are BRL.Max2D (named on both sides).
'  * GetScale's two arguments are Var params, so `RenderStatus.ScaleX/ScaleY` are
'    passed by address -- that is the `RenderStatus+0x10 / +0x14` pair in the decompile.
'  * The two TDrawTextAction blocks are separate Locals; field stores are in the
'    original's order Font, Text, X, Y (not declaration order).
'  * Matched first attempt, reloc_masked=17.

Method DrawTextLine:Int(a0:String, a1:Float, a2:Float, a3:Int, a4:TBitmapFont)
	If a4.RenderFX <> Null
		Local a:TDrawTextAction = New TDrawTextAction
		a.Font = a4
		a.Text = a0
		a.X = a1
		a.Y = a2
		a4.RenderFX.DrawTextBegin(a)
	End If
	RenderStatus.OldBlend = GetBlend()
	GetScale(RenderStatus.ScaleX, RenderStatus.ScaleY)
	RenderStatus.Rotation = GetRotation()
	If DrawShadow <> 0
		If a3 = 1 Then SetBlend(ShadowBlend)
		DrawShadowText(a0, a1, a2, a4)
	End If
	If DrawBorder <> 0
		If a3 = 1 Then SetBlend(BorderBlend)
		DrawBorderText(a0, a1, a2, a4)
	End If
	If a3 = 1 Then SetBlend(FaceBlend)
	DrawFaceText(a0, a1, a2, a4)
	SetBlend(RenderStatus.OldBlend)
	If a4.RenderFX <> Null
		Local b:TDrawTextAction = New TDrawTextAction
		b.Font = a4
		b.Text = a0
		b.X = a1
		b.Y = a2
		a4.RenderFX.DrawTextEnd(b)
	End If
End Method
