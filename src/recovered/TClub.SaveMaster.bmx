' TClub.SaveMaster
' VA 0x004C133B   305 bytes   class-table slot 0x5C   sig (i,i)i   KIND=Function (static)
' byte-identical vs NSS5.exe (305/305, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=25)
'
' ASSUMPTIONS
'  Parameters: a0 = "prompt before overwriting", a1 = "mobile format".
'  Module Global -- NAME IS OURS, TYPE is load-bearing:
'    0x00C6E950 String  g_datapath   (globals_final type_source='verified', high; the
'                                     table's NAME g_promotionplace_int05 is wrong for
'                                     this use but the TYPE String is authoritative)
'  Slots resolved:
'    [0x00C61CC0] = TScreen class table + 0x94 = TScreen.DoMessage($,i,i)i
'    [0x00C59E00] = TClub   class table + 0x54 = TClub.WriteData(:TStream)i
'    [0x00C59E04] = TClub   class table + 0x58 = TClub.WriteDataMobile(:TStream)i
'                   -> both are sibling Functions of THIS Type, so written WITHOUT the
'                      `TClub.` prefix (they compile to the same indirect class-table call)
'  BRL/runtime:
'    0x004A7C20 _bbStringConcat, 0x004A75B0 _bbStringReplace (-> .Replace)
'    0x005B5A99 _brl_filesystem_FileType, 0x005B5578 _brl_filesystem_StripDir,
'    0x005B65FC _brl_filesystem_WriteFile, 0x004C5549 GetText (module Function, ONE arg)
'  ARG COUNTS were read off the stack, not off Ghidra: StripDir and GetText each take one
'  argument (`add esp,4`); the extra pushes Ghidra folds into them are DoMessage's.
'  Literals: 0x00C70618 "GameMedia/Data/Clubs.csv", 0x00C70C90
'    "GameMedia/Data/Mobile/Clubs.txt", 0x00C704A4 "$filename",
'    0x00C704C4 "CMESSAGE_OVERWRITEFILE", 0x00C704FC "CMESSAGE_FILENOTCREATED",
'    0x00C6FDF0 "utf8::".
'  SHAPE: the three-way `And` chain is one guarded early return (`mov eax,0 / jmp epilogue`
'  at 0x004C13D5), not nested Ifs. `cmp edx,0x5C9C80 / setne / movzx / cmp eax,0 / jne`
'  at 0x004C13F8 is the `If Not s` emission (codegen-patterns 10.3), with the null branch
'  ending in its own `Return 0` -- no Else.
	'!Global g_datapath:String
	Function SaveMaster:Int(a0:Int, a1:Int)
		Local fn:String = g_datapath + "GameMedia/Data/Clubs.csv"
		If a1 Then fn = g_datapath + "GameMedia/Data/Mobile/Clubs.txt"
		If a0 And FileType(fn) = 1 And TScreen.DoMessage(GetText("CMESSAGE_OVERWRITEFILE").Replace("$filename", StripDir(fn)), 1, 0) = 0 Then Return 0
		Local s:TStream = WriteFile("utf8::" + fn)
		If Not s
			TScreen.DoMessage(GetText("CMESSAGE_FILENOTCREATED").Replace("$filename", StripDir(fn)), 0, 0)
			Return 0
		EndIf
		If a1
			WriteDataMobile(s)
		Else
			WriteData(s)
		EndIf
	End Function
