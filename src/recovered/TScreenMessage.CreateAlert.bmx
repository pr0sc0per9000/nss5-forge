' TScreenMessage.CreateAlert
' VA 0x00570659   330 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i,i,$,i,$,$,:TImage,i,i,i,i,i)i, class-table slot 0x48
' ASSUMPTIONS
'   '!Global g_fonts:TImageFont[]  -- 0x00C61710; the code does `mov eax,[g] / push
'     [eax+0x20]`, i.e. element 2 of a BBArray (data at +0x18). Element type is
'     TImageFont because the value goes straight into SetImageFont.
'   '!Global g_matchtime:Int  -- 0x00C6EFD4 (same Global TScreenMessage.Create uses)
'   '!Global g_pausedms:Int   -- 0x00C6EFD8 (ditto)
'   TScreenMessage fields x +0x08, y +0x0c, starttime +0x14, delaytime +0x18,
'   finishtime +0x1c, alfa +0x24, lbl +0x38 (object_model.json).
'   0x004A7FB0 is Max(Int,Int): `mov edx,[esp+4] / mov eax,[esp+8] / cmp eax,edx /
'   jge / mov eax,edx`, so the FIRST argument is the one at [esp+4] = ImageHeight.
'   String literals read out of the exe: 0x00C8F608 "CreateAlert:", 0x00C8F62C "alert".
'   The 20th CreateLabel argument is the empty string at 0x005C7D40.
' CODEGEN NOTES
'   `a8 :+ ImageWidth(a6) + 20` is load-bearing: it emits `add eax,0x14 / add edi,eax`.
'   `a8 = a8 + ImageWidth(a6) + 20` groups the other way and costs 4 extra bytes
'   (334 vs 330) via an ebx spill.
'   `m.alfa = 0.0` emits `fldz / fstp` -- Create sets 1.0 here, CreateAlert sets 0.
'   message / colour / bmfnt / img are never assigned; the Label carries them instead.
	Function CreateAlert:Int(a0:Int, a1:Int, a2:String, a3:Int, a4:String, a5:String, a6:TImage, a7:Int, a8:Int, a9:Int, a10:Int, a11:Int)
		'!Global g_fonts:TImageFont[]
		'!Global g_matchtime:Int
		'!Global g_pausedms:Int
		LogLine("CreateAlert:" + a2)
		Local m:TScreenMessage = New TScreenMessage
		m.x = a0
		m.y = a1
		m.starttime = MilliSecs() - g_pausedms
		m.delaytime = a3
		m.finishtime = g_matchtime + a3
		m.alfa = 0.0
		If a8 = 0
			SetImageFont(g_fonts[2])
			a8 = TextWidth(a2) + 20
			If a6 <> Null
				a8 :+ ImageWidth(a6) + 20
			EndIf
			a9 = Max(ImageHeight(a6), TextHeight(a2)) + 20
		EndIf
		m.lbl = TLabel.CreateLabel("alert", a2, a0, a1, a8, a9, a7, a4, a5, 0, a11, 0, 1, a10, a6, 0, 0, 0, 0, "", 0)
	End Function
