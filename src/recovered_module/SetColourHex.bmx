' SetColourHex  -- module-level Function (no Type)
' VA 0x00505cea   184 bytes   sig ($)i
' byte-identical vs NSS5.exe (184/184, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Parses an RGB hex string and calls SetColor. A string longer than 6
' characters is assumed to carry a 3-character prefix, which is dropped. The "$" pushed
' before each concat is the 1-character BlitzMax string object at 0x00C7529C, so the
' components are parsed as hex by _bbStringToInt.
'
' THE THREE LOCALS ARE LOAD-BEARING. Written as SetColor Int(..), Int(..), Int(..) this
' compiles to 176 bytes: bcc evaluates call arguments right to left and pushes each
' result straight from eax, so the components come out in the order b, g, r. The original
' computes them in source order into ebx/edi/eax and only then pushes, which is what
' Locals emit. With the Locals it is exact.
	Function SetColourHex:Int(a0:String)
		If a0.length < 6 Then Return 0
		If a0.length > 6 Then a0 = a0[3..]
		Local r:Int = Int("$"+a0[0..2])
		Local g:Int = Int("$"+a0[2..4])
		Local b:Int = Int("$"+a0[4..6])
		SetColor r, g, b
	End Function
