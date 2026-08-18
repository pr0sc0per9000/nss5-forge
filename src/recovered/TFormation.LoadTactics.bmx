' TFormation.LoadTactics
' VA 0x004d8783   453 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ($)i, class-table slot 0x3c   (reloc_masked=34)
' ASSUMPTIONS
'   '!Global g_datapath:String  -- 0x00C6E950, the install/EngineMedia root path.
'     globals_final types it Int; it is concatenated with String literals here, which is
'     String (11.2: refcount/concat traffic decides the type, not the table).
'   '!Global g_userpath:String  -- 0x00C6E9A8, the writable user directory. Same argument.
'   Self.name +0x08 $, Self.m_TacPos +0x20 []i (array data at +0x18).
'   BRL alias sets picked by context (10.8): 0x005B80B9 = Eof, 0x005B82EF = ReadLine,
'     0x005B812B = CloseStream.  0x005B5A99 = FileType, 0x005B65E3 = ReadFile.
'   LogLine is src/recovered_module/LogLine.bmx (0x00505B91).
'   String literals read out of .data with harness.read_string: 0x00C74A34
'     "Loading Tactics:", 0x00C74A20 ".tac", 0x00C74A60 "EngineMedia\Tactics\",
'     0x00C74A94 "Tactics\", 0x00C74AB0 "EngineMedia\Tactics\4-4-2.tac",
'     0x00C74AF8 "Cannot find tactics: ".
' SHAPE NOTES
'   * the stream test is the early-return form `If Not s ... Return 0` (3f/10.9):
'     setne/movzx/cmp 0/jne over a `mov eax,0; jmp end`. An If/Else came out 15 short.
'   * the loop is `To 34` -- `cmp esi,0x22 / jle` (6). `Until 35` would emit `jl`.
'   * cnt is declared before i: bcc emits `mov edi,0` then `mov esi,0` in that order.
	Method LoadTactics:Int(a0:String)
		'!Global g_datapath:String
		'!Global g_userpath:String
		LogLine("Loading Tactics:" + a0 + ".tac")
		Local f:String = g_datapath + "EngineMedia\Tactics\" + a0 + ".tac"
		If FileType(f) <> 1
			f = g_userpath + "Tactics\" + a0 + ".tac"
		EndIf
		If FileType(f) <> 1
			f = g_datapath + "EngineMedia\Tactics\4-4-2.tac"
		EndIf
		Local s:TStream = ReadFile(f)
		If Not s
			LogLine("Cannot find tactics: " + a0 + ".tac")
			Return 0
		EndIf
		Self.name = a0
		Local cnt:Int = 0
		For Local i:Int = 0 To 34
			If Not Eof(s) And cnt < 11
				Self.m_TacPos[i] = Int(ReadLine(s))
				If Self.m_TacPos[i] = 1
					cnt = cnt + 1
				Else
					Self.m_TacPos[i] = 0
				EndIf
			EndIf
		Next
		CloseStream(s)
		Self.UpdateLabels()
	End Method
