' TMyStream.ReadLine
' VA 0x0050833C   364 bytes   vtable slot 0x8c   sig ()$
' byte-identical vs NSS5.exe (364/364, original length from Ghidra's inventory)
' mode=reloc, reloc_masked=15: E8 calls into brl.stream.TStream/TStreamWrapper (Seek,
' ReadInt, ReadString, ReadBytes -- all inherited, dispatched through Self's own vtable
' slots 0x3c/0x6c/0x94/0x50), the Super.ReadLine() call into TStreamWrapper.ReadLine
' (0x005B7B69), _bbStringContains (0x004A6BF0) and _bbStringFromShorts (0x004A7700 --
' confirmed against brl.mod/textstream.mod/textstream.bmx's own ReadLine, which calls
' String.FromShorts the same way; not in extracted/runtime_helpers.tsv before this body,
' now recorded there), plus two _bbArrayNew1D calls for the Short[] read buffer (one per
' textually-duplicated branch, hence two different RTTI operands for the same Short[]
' array type).
'
' Self.stream (TStreamWrapper's own Field, "_stream") holds the wrapped TStream; "Not x"
' is the tell for BlitzMax Null tests here (section 10.3) -- NOT "x = Null", which is 12
' bytes shorter and was the first thing tried and rejected on length.
' Self.oldversion caches the detected save format: -1 undetected, 0 new (length-prefixed
' UTF-16), 1 old (plain newline-terminated, delegates to Super.ReadLine()). The three-way
' branch loads oldversion into a register ONCE and compares that register three times --
' the tell for Select/Case over If/ElseIf, which reloads the Field from memory each time
' and cost 9 extra bytes when tried first.

	Method ReadLine:String()
		If Not _stream Then Return "STREAM ERROR"

		Select oldversion
			Case -1
				ReadInt()
				Local qc:String = ReadString(1)
				If qc.Contains("#")
					oldversion = 0
					Seek(0)
					Local n:Int = ReadInt()
					If n = 0 Then Return ""
					Local buf:Short[n]
					ReadBytes(buf, n*2)
					Return String.FromShorts(buf, n)
				Else
					oldversion = 1
					Seek(0)
					Return Super.ReadLine()
				EndIf
			Case 0
				Local n:Int = ReadInt()
				If n = 0 Then Return ""
				Local buf:Short[n]
				ReadBytes(buf, n*2)
				Return String.FromShorts(buf, n)
			Case 1
				Return Super.ReadLine()
		End Select
		Return ""
	End Method
