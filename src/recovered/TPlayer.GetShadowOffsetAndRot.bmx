' TPlayer.GetShadowOffsetAndRot
' VA 0x004EEFDC, 89 bytes
' byte-identical vs NSS5.exe

	Method GetShadowOffsetAndRot:Int(dir:Int, rot:Int Ptr, yoff:Int Ptr)
		If ImageFalling()
			rot[0] = -1
		ElseIf ImageJumping()
			rot[0] = -1
			yoff[0] = yoff[0] + 20
		Else
			yoff[0] = yoff[0] + 20
		End If
	End Method
