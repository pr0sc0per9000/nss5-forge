' TBase_Team.GetStringArrayFixtureList
' VA 0x004BD132   143 bytes
' byte-identical vs NSS5.exe (143/143, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
Local l:TList = CreateList()
For Local f:TFixture = EachIn Self.GetFixtureList(a0, 0)
	Local sa:String[] = f.GetStringArrayForTeamId(Self.id)
	If sa Then l.AddLast(sa)
Next
Return l
