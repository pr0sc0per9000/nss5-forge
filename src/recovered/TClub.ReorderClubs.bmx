' TClub.ReorderClubs  -- KIND=Function (static method on TClub), slot 0x88
' VA 0x004C1FC3   412 bytes   sig ()i
' byte-identical vs NSS5.exe (412/412, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=20)
'
' ASSUMPTIONS
'  Module Global declared (name is ours):
'    0x00C59A44 g_clubs : TList   -- globals_final.tsv types it only as "Object"
'                (type_source=usage, confidence=low). TList is proved by the call sites:
'                every use here goes through slot 0x8C = TList.ObjectEnumerator.
'  Class-table slot resolved:
'    [0x00C59E40] = TClub + 0x94 = SortListBy(i,i)i -> TClub.SortListBy(20, 1)
'  Direct calls resolved:
'    0x00505B91 -> LogLine (src/recovered_module/LogLine.bmx)
'    0x004A7F60 -> integer Abs.  Not in runtime_helpers.tsv or brl_functions.tsv; I
'                disassembled it: mov eax,[esp+4] / mov edx,eax / sar edx,31 / xor eax,edx
'                / sub eax,edx / ret -- the standard branchless integer absolute value.
'                Writing Abs(x) reproduces the call exactly.
'  Fields: id/rivalid1/rivalid2/rivalid3 are inherited from TBase_Team (+0x0C, +0x28,
'  +0x2C, +0x30); bteamofid is TClub's own (+0x70).
'  The log string literal is pushed as an absolute data address, so its TEXT is not
'  recoverable from the bytes -- the wording below is a guess.

	Function ReorderClubs:Int()
		'!Global g_clubs:TList
		LogLine("ReorderClubsByName")
		TClub.SortListBy(20, 1)
		Local n:Int = -1
		For Local c:TClub = EachIn g_clubs
			For Local c2:TClub = EachIn g_clubs
				If c2.rivalid1 = c.id Then c2.rivalid1 = n
				If c2.rivalid2 = c.id Then c2.rivalid2 = n
				If c2.rivalid3 = c.id Then c2.rivalid3 = n
				If c2.bteamofid = c.id Then c2.bteamofid = n
			Next
			c.id = n
			n = n - 1
		Next
		For Local c:TClub = EachIn g_clubs
			c.id = Abs(c.id)
			c.rivalid1 = Abs(c.rivalid1)
			c.rivalid2 = Abs(c.rivalid2)
			c.rivalid3 = Abs(c.rivalid3)
			c.bteamofid = Abs(c.bteamofid)
		Next
	End Function
