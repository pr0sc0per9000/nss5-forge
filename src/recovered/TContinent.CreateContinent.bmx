' TContinent.CreateContinent
' VA 0x00508997   486 bytes   vtable slot 0x30   sig ($)i
' byte-identical vs NSS5.exe (486/486, original length from Ghidra's inventory)
' VA        0x00508997   slot 0x30   KIND=Function (static)   SIG=($)i
' ORACLE    MATCH mode=reloc  486/486 bytes  reloc_masked=28
'
' NO module Globals are used by this function.
'
' CALL TARGETS RESOLVED
'   0x00505BCB -> module Function NextFieldInt($ Var,$)i   (src/recovered_module)
'   0x00505C64 -> module Function NextField($ Var,$)$      (src/recovered_module)
'   0x004A8F20 -> `New TContinent` (bbObjectNew on the TContinent class table)
'   0x004A8590 -> inlined BBRELEASE's GC free; never written in source
'   The separator constant at 0x00C6FCC0 is the one-character BBString TAB, so the second
'   argument is the literal "~t" (read out of NSS5.exe's string pool).
'
' FIELD OFFSETS (object_model.json, TContinent)
'   +0x08 id:Int  +0x0C name:$  +0x10 tla:$  +0x14 continentality:$
'   +0x18 federationname:$  +0x1C federationshortname:$  +0x20 strength:Int
'
' SOURCE-FORM NOTE (cost one iteration)
'   The guard is an EARLY RETURN spelled `< 1`, not an If-block spelled `> 0`.
'   Original: `cmp ebx,1 / jge +0x0A / mov eax,0 / jmp <epilogue>`.
'   `If id > 0 ... EndIf` gives `cmp ebx,0 / jle <far>` and comes out 480 bytes (6 short).
'   Per guide 10.1 the relational spelling is byte-observable: match the immediate on the
'   `cmp`, not the meaning.
'
'   `Local line:String = a0` is real, not a compiler temp: the incoming String is copied
'   into [ebp-4] with a retain, and every NextField/NextFieldInt call passes `lea eax,[ebp-4]`
'   (a String Var) with a retain/release pair bracketing the call.

Function CreateContinent(a0:String)
	Local line:String = a0
	Local id:Int = NextFieldInt(line, "~t")
	If id < 1 Then Return 0
	Local c:TContinent = New TContinent
	c.id = id
	c.name = NextField(line, "~t")
	c.tla = NextField(line, "~t")
	c.continentality = NextField(line, "~t")
	c.federationname = NextField(line, "~t")
	c.federationshortname = NextField(line, "~t")
	c.strength = NextFieldInt(line, "~t")
End Function
