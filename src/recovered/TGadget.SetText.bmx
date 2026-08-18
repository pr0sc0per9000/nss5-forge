' TGadget.SetText
' VA 0x005141DC   824 bytes   vtable slot 0x64   sig ($,$,i,i)i
' byte-identical vs NSS5.exe (824/824, original length from Ghidra's inventory, mode=reloc)
' The word-wrap engine behind every gadget's caption -- 118 CreatePanel/197 CreateLabel
' call sites reach it.
' assumptions:
'   TGadget +0x10 txt, +0x14 txtalignx, +0x18 txtlines:TList, +0x1c txtw:Float,
'     +0x2c w:Float, +0x34 txtcolour, +0x4c fntSize; slot 0x5C = SetFontSize(i)
'   TList slots 0x34 Clear, 0x38 IsEmpty, 0x44 AddLast  (0x38 is IsEmpty, not Count --
'     the reflection order is Clear, IsEmpty, Contains, AddFirst, AddLast)
'   0x005AE1AB = _brl_max2d_TextWidth
'   The three float margins are separate .rdata constants: 8.0, 8.0, 28.0.
' Form notes that are load-bearing:
'   x87 comparisons emit the NEGATED predicate + `jne <skip>`, so `If a > b` shows up as
'   setbe/jne. Both `<= Self.w - 8` branches are therefore written then-first.
'   `s :+ Self.txt[0..p] + " "` (not `s = s + ... + " "`): the inner concat runs BEFORE the
'   accumulator concat, which is the section-16.1 tell for `:+`.
	Method SetText:Int(a0:String, a1:String, a2:Int, a3:Int)
		Self.txt = a0
		If a1.length <> 0 Then Self.txtcolour = a1
		If a2 > -1 Then Self.txtalignx = a2
		If a3 > -1 Then Self.fntSize = a3
		Self.SetFontSize(Self.fntSize)
		Self.txtlines.Clear()
		Self.txtw = TextWidth(Self.txt)
		If Self.txtw > Self.w
			Local s:String = ""
			Repeat
				Local p:Int = Self.txt.Find(" ")
				If p = -1
					If TextWidth(s + Self.txt) <= Self.w - 8
						Self.txtlines.AddLast(s + Self.txt)
					Else
						Self.txtlines.AddLast(s)
						Self.txtlines.AddLast(Self.txt)
					End If
					Self.txt = ""
				Else
					If TextWidth(s + Self.txt[0..p]) <= Self.w - 8
						s :+ Self.txt[0..p] + " "
						Self.txt = Self.txt[p + 1..Self.txt.length]
					Else
						If s <> ""
							Self.txtlines.AddLast(s)
							s = ""
						Else
							If Self.txtlines.IsEmpty() And s = "" Then Exit
							Repeat
								s :+ Chr(Self.txt[0])
								If Self.txt.length <> 0
									Self.txt = Self.txt[1..Self.txt.length]
								End If
								If TextWidth(s) > Self.w - 28
									Self.txtlines.AddLast(s)
									s = ""
									Exit
								End If
							Until Self.txt = ""
						End If
					End If
				End If
			Until Self.txt.length <= 1
			Self.txt = a0
		End If
	End Method
