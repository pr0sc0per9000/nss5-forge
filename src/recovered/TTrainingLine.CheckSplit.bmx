' TTrainingLine.CheckSplit
' VA 0x0058414C   366 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0x4c
' ASSUMPTIONS
'   Inherited TTrainingObject fields x +0x10, y +0x14, alive +0x18; own fields
'   colour $ +0x24, x2 i +0x28, y2 i +0x2c (object_model.json).
'   TBall fields oldx +0x24, oldy +0x28, x +0x18, y +0x1c, lastkicktype +0x68.
'   TPlayer fields oldx +0x58, oldy +0x5c, x +0x4c, y +0x50.
'   0x00505E20 is the recovered module Function GetInterceptPoint (src/recovered_module).
'   String literals read out of the exe: 0x00C725EC "FF0000", 0x00C75434 "00FFFF",
'   0x00C6E904 "00FF00".
' CODEGEN NOTES
'   Both `colour = "FF0000"` tests are EARLY RETURNS, not enclosing blocks -- the
'   enclosing form is 353 bytes (13 short).
'   The TInterceptPoint result is used directly (`cmp dword [eax+0x18],0`), NOT stored
'   in a Local.
'   x2/y2 are Int fields passed to Float parameters; bcc emits the fild/fstp conversion.
	Method CheckSplit:Int()
		If alive = 0 Then Return 0
		Local b:TBall = TBall.GetActiveBall()
		If colour = "FF0000" Then Return 0
		If b <> Null
			If colour = "00FFFF" And b.lastkicktype < 4 Then Return 0
			If GetInterceptPoint(x, y, x2, y2, b.oldx, b.oldy, b.x, b.y).intercept <> 0
				KillMe()
				Return 0
			EndIf
		EndIf
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If p <> Null And colour = "00FF00"
			If GetInterceptPoint(x, y, x2, y2, p.oldx, p.oldy, p.x, p.y).intercept <> 0
				KillMe()
				Return 0
			EndIf
		EndIf
	End Method
