' TScreen_Stable.LoadData
' VA 0x00587c3a   1194 bytes   vtable slot 0x38   sig (:TStream)i   KIND=Function
' byte-identical vs NSS5.exe (1194/1194, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=84), verified with NSS5_NO_LEARN=1.
'
' Two modes: with no stream it GENERATES random horses from Horse.ini; with a stream it
' parses a saved CSV.  Global names are ours; the types are load-bearing:
'   0x00C6E950 g_datapath:String   0x00C6E294/0x00C6E298 TGadget (only slot 0x34 Update)
'
' THE ARRAY LITERAL IS LOAD-BEARING.  Written as `New Int[5]` + five `st[n] = Rand(6)`
' statements this comes out 1192 bytes: the original carries an extra `mov esi,ebx` at
' 0x00587D20 that is the array-literal temporary being copied into the declared Local after
' all five elements are filled.  `[Rand(6),Rand(6),Rand(6),Rand(6),Rand(6)]` reproduces it.
' `Rand(6)` (maxValue defaulting to 1) is what emits `push 1 / push 6`.
' `If ln = "//" Then Exit` -- a 5-byte `jmp` to the loop end, NOT `Return 0` (which would
' also have to emit `mov eax,0`).
'!Global g_datapath:String
'!Global g_stable_tbl01:TGadget
'!Global g_stable_tbl02:TGadget
LogLine("LoadHorseData")
If g_stable_tbl01 <> Null Then g_stable_tbl01.Update()
If g_stable_tbl02 <> Null Then g_stable_tbl02.Update()
If Not a0
	a0 = ReadFile(g_datapath + "GameMedia\Data\Horse.ini")
	Local n:Int = 0
	While Not Eof(a0)
		Local st:Int[] = [Rand(6), Rand(6), Rand(6), Rand(6), Rand(6)]
		Local price:Int = 0
		For Local i:Int = 0 To 4
			Select st[i]
			Case 1
				price :+ 50000
			Case 2
				price :+ 25000
			Case 3
				price :+ 10000
			End Select
		Next
		THorse.Create(n, ReadLine(a0), Rand(80,100), Rand(80,100), Rand(40,100), st, price, 0, 0, Rand(4))
		n :+ 1
	Wend
	CloseFile(a0)
	TScreen_Stable.SetUpHorsesForSale()
Else
	While Not Eof(a0)
		Local ln:String = ReadLine(a0)
		If ln = "//" Then Exit
		If Left(ln, 1) <> ";"
			Local p:Int = ln.Find(",", 0)
			Local v1:Int = Int(ln[..p])
			ln = ln[p+1..]
			p = ln.Find(",", 0)
			Local v2:String = ln[..p]
			ln = ln[p+1..]
			p = ln.Find(",", 0)
			Local v3:Float = Float(ln[..p])
			ln = ln[p+1..]
			p = ln.Find(",", 0)
			Local v4:Float = Float(ln[..p])
			ln = ln[p+1..]
			p = ln.Find(",", 0)
			Local v5:Float = Float(ln[..p])
			ln = ln[p+1..]
			Local st2:Int[] = New Int[5]
			For Local i:Int = 0 To 4
				p = ln.Find(",", 0)
				st2[i] = Int(ln[..p])
				ln = ln[p+1..]
			Next
			p = ln.Find(",", 0)
			Local v6:Int = Int(ln[..p])
			ln = ln[p+1..]
			p = ln.Find(",", 0)
			Local v7:Int = Int(ln[..p])
			ln = ln[p+1..]
			p = ln.Find(",", 0)
			Local v8:Int = Int(ln[..p])
			ln = ln[p+1..]
			Local v9:Int = Int(ln)
			THorse.Create(v1, v2, v3, v4, v5, st2, v6, v7, v8, v9)
		End If
	Wend
End If
