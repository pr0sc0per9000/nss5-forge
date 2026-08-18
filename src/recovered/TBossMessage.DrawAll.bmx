' TBossMessage.DrawAll
' VA 0x00570A47   249 bytes   vtable slot 0x38   sig (f,f,f)i   KIND=Function (static)
' byte-identical vs NSS5.exe (249/249, original length from Ghidra's inventory, mode=reloc)
' assumptions: Global 0x00C6B284 declared TList (globals_final.tsv says only "Object"; slot
' 0x8C = TList.ObjectEnumerator settles it, and the downcast class table 0x00C6B3E0 is
' TBossMessage). Global 0x00C61710 declared TImageFont[] -- the load is [array+0x20], i.e.
' element 2 of a 1-D array whose data starts at +0x18, handed straight to SetImageFont.
' 0x00506456 is module Function SetDrawStateHex; "FFFFFF" is the object at 0x00C5D680.
'
' `Local t:Int = 0` is a real statement: `mov esi,0` sits between SetScale and the
' enumerator call, so the declaration is at that point in source order.
' t+500 is written twice on purpose -- bcc does no CSE and the original recomputes it.
	Function DrawAll:Int(a0:Float, a1:Float, a2:Float)
		'!Global g_bossmessages:TList
		'!Global g_fonts:TImageFont[]
		If Not g_bossmessages Then Return 0
		SetImageFont(g_fonts[2])
		SetScale(1.0, 1.0)
		Local t:Int = 0
		For Local m:TBossMessage = EachIn g_bossmessages
			If m.starttime < t
				m.starttime = t + 500
				m.finishtime = t + 500 + m.delaytime
			EndIf
			m.Draw(a0, a1, a2)
			t = m.finishtime
		Next
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	End Function
