' TStadium.WriteData
' VA 0x00527979   345 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_stadiums:TList        ' 0x00C64BC0
WriteLine(a0, "id~tname~tnation~tcapacity~tlongitude~tlatitude")
For Local s:TStadium = EachIn g_stadiums
	Local ln:String = String(s.id) + "~t"
	ln :+ s.name + "~t"
	ln :+ String(s.nation) + "~t"
	ln :+ String(s.capacity) + "~t"
	ln :+ String(s.longitude) + "~t"
	ln :+ String(s.latitude)
	WriteLine(a0, ln)
Next
WriteLine(a0, "//")
