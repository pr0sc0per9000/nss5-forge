' InsertString  -- module-level Function (no Type)
' VA 0x00507586   101 bytes   sig ($ Var,$,i)i
' byte-identical vs NSS5.exe (101/101, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=5, verified with NSS5_NO_LEARN=1 -- codegen-patterns 13.1)
'
' NAME IS OURS. Splices a1 into a0 at character index a2, in place. Two _bbStringSlice
' calls and two _bbStringConcat calls; the string is a Var parameter, so the whole body is
' the single assignment. Recovered as the blocker under GroupDigits (0x00507474), which is
' in turn the blocker under FormatMoney (0x0050720B, gates 18).
'
' Needs an explicit `decl` in the probe: the reflection signature grammar encodes both Ptr
' and Var as `*`, and `String Var` has no Ptr spelling.
	Function InsertString:Int(s:String Var, a1:String, a2:Int)
		s = s[..a2] + a1 + s[a2..]
	End Function
