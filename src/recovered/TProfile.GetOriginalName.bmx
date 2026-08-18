' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TProfile.GetOriginalName
' VA 0x0056d318   79 bytes   vtable slot 0x160   sig ()$
' byte-identical vs NSS5.exe (79/79, original length from Ghidra's inventory, mode=reloc)
' Both search literals are placeholders (their addresses are relocation-masked); the local
' name 'p' is invented -- neither affects codegen.
'
' FALSE-POSITIVE HAZARD. If the runtime-helper table learns 0x004A6C20 as _bbStringFind,
' the call operand is masked by name and a Find() body passes as byte-identical when it
' is not. 0x004A6C20 is _bbStringFindLast -- it loads both string lengths up front and
' computes len-start, scanning backward -- whereas the genuine _bbStringFind at
' 0x004A6B60 branchlessly clamps a negative start (`xor eax,-1 / sar eax,31`). Both call
' sites in this function target 0x004A6C20. With the table right, a Find() body is
' rejected at 64/79 and the FindLast() body below is exact.
'
' Splitting on the LAST separator is the semantically right reading too: it strips the
' surname off a full player name.
	Method GetOriginalName:String()
		Local p:Int = name.FindLast("#")
		If p = -1 Then p = name.FindLast("@")
		If p >= 0
			Return name[..p]
		Else
			Return name
		EndIf
	End Method
