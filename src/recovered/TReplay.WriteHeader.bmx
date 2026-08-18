' TReplay.WriteHeader
' VA 0x0050444E   590 bytes   vtable slot 0x38   sig (:TStream)i   KIND=Method
' byte-identical vs NSS5.exe (590/590, original length from Ghidra's inventory, mode=reloc)
' assumptions: no module Globals needed.
' calls resolved:
'   0x005B8307 = _brl_stream_WriteLine, the MODULE Function WriteLine(stream, str$)
'   TStream slot 0x90 = TStream.WriteLine($) -- the METHOD
' Both forms genuinely occur in this one body and they are different bytes: every field is
' written with the module function WriteLine(a0, ...) EXCEPT teamname1 and teamname2, which
' go through the method a0.WriteLine(...). That is not a decompiler artefact -- the two
' string fields emit `mov eax,[ebx] / call [eax+0x90]` while everything else emits a direct
' E8 to 0x005B8307.
' 0x004A7AC0 _bbStringFromInt supplies the Int->String coercion for the Int fields;
' 0x004A7C20 _bbStringConcat builds the final tab-separated line.
' fields: TReplay +0x08 name$, +0x0C teamid1, +0x10 teamid2, +0x14 teamname1$,
'   +0x18 teamname2$, +0x1C score1, +0x20 score2, +0x24 pitchtype, +0x28 mowtype,
'   +0x2C doingweather, +0x30 weathertype, +0x34/38/3C/40 the four :TKitStrings,
'   +0x44 fixlevel, +0x48 stadiumsize; TKitStrings +0x08 style, +0x0C shirt1,
'   +0x10 shirt2, +0x14 shorts, +0x18 socks (all $).
' The literal at 0x00C6FCC0 is a single tab character, written "~t".
	Method WriteHeader:Int(a0:TStream)
		WriteLine(a0, Self.name)
		WriteLine(a0, Self.teamid1)
		WriteLine(a0, Self.teamid2)
		a0.WriteLine(Self.teamname1)
		a0.WriteLine(Self.teamname2)
		WriteLine(a0, Self.score1)
		WriteLine(a0, Self.score2)
		WriteLine(a0, Self.pitchtype)
		WriteLine(a0, Self.mowtype)
		WriteLine(a0, Self.doingweather)
		WriteLine(a0, Self.weathertype)
		WriteLine(a0, Self.kit1cols.style)
		WriteLine(a0, Self.kit1cols.shirt1)
		WriteLine(a0, Self.kit1cols.shirt2)
		WriteLine(a0, Self.kit1cols.shorts)
		WriteLine(a0, Self.kit1cols.socks)
		WriteLine(a0, Self.kit2cols.style)
		WriteLine(a0, Self.kit2cols.shirt1)
		WriteLine(a0, Self.kit2cols.shirt2)
		WriteLine(a0, Self.kit2cols.shorts)
		WriteLine(a0, Self.kit2cols.socks)
		WriteLine(a0, Self.keeperkit1cols.style)
		WriteLine(a0, Self.keeperkit1cols.shirt1)
		WriteLine(a0, Self.keeperkit1cols.shirt2)
		WriteLine(a0, Self.keeperkit1cols.shorts)
		WriteLine(a0, Self.keeperkit1cols.socks)
		WriteLine(a0, Self.keeperkit2cols.style)
		WriteLine(a0, Self.keeperkit2cols.shirt1)
		WriteLine(a0, Self.keeperkit2cols.shirt2)
		WriteLine(a0, Self.keeperkit2cols.shorts)
		WriteLine(a0, Self.keeperkit2cols.socks)
		WriteLine(a0, Self.fixlevel + "~t" + Self.stadiumsize)
	End Method
