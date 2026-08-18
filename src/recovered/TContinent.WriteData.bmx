' TContinent.WriteData
' VA 0x00508c9a   346 bytes
' byte-identical vs NSS5.exe (346/346, original length from Ghidra's inventory, mode=reloc, 29 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Function (:TStream)i, vtable slot 0x38.
' ASSUMPTIONS: header/terminator literals masked. The `s :+ x + ","` shape (not a flat
' left-associative chain) is what produces the paired bbStringConcat grouping.
'!Global g_continents:TList
WriteLine(a0, "id~tname~ttla~tcontinentality~tfederationname~tfederationshortname~tstrength")
For Local c:TContinent = EachIn g_continents
	Local s:String = String(c.id) + "~t"
	s :+ c.name + "~t"
	s :+ c.tla + "~t"
	s :+ c.continentality + "~t"
	s :+ c.federationname + "~t"
	s :+ c.federationshortname + "~t"
	s :+ String(c.strength)
	WriteLine(a0, s)
Next
WriteLine(a0, "//")
