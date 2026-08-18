' TStadium.CreateStadium
' VA        0x0052771E   slot 0x30   KIND=Function (static)   SIG=($)i
' ORACLE    MATCH mode=reloc  377/377 bytes  reloc_masked=23
'
' NO module Globals are used by this function.
'
' CALL TARGETS RESOLVED
'   0x00505BCB -> module Function NextFieldInt($ Var,$)i   (src/recovered_module)
'   0x00505C64 -> module Function NextField($ Var,$)$      (src/recovered_module)
'   0x004A8F20 -> `New TStadium` (bbObjectNew on the TStadium class table)
'   0x004A8590 -> inlined BBRELEASE's GC free; never written in source
'   0x004A6E90 -> _bbStringToFloat, i.e. the `Float(...)` cast of a String.
'                 runtime_helpers.tsv carries 0x004a6e90 = _bbStringToFloat with 149
'                 witnesses, and this body was re-run under NSS5_NO_LEARN=1 as a
'                 two-directional discrimination on this very function (guide 15.3 form):
'                     Float(...) 377/377   .ToFloat() 377/377   <- accepted, learned=None
'                     Double(...) 302/377  .ToDouble() 302/377  <- rejected, same length
'                 Equal length in all four, so length constrains nothing and the reject is
'                 real content. Do NOT re-read the callee's `fld qword` return spill as a
'                 Double (guide 15.4): that width is how GCC preserved the value across
'                 bbMemFree, not a declared return type.
'   The separator constant at 0x00C6FCC0 is the one-character BBString TAB (confirmed with
'   harness.read_string), so the second argument is the literal "~t".
'
' FIELD OFFSETS (object_model.json, TStadium)
'   +0x08 id:Int  +0x0C name:$  +0x10 nation:Int  +0x14 capacity:Int
'   +0x18 longitude:Float  +0x1C latitude:Float
'
' SOURCE FORM
'   Same family as TContinent.CreateContinent (0x00508997) and
'   TPromotionPlace.CreatePromotionPlace -- one line of tab-separated text parsed field by
'   field. The guard is the EARLY-RETURN spelling `< 1` (cmp ebx,1 / jge), not `> 0`.
'   `Local line:String = a0` is real: the incoming String is copied to [ebp-4] with a
'   retain, and every NextField/NextFieldInt call passes `lea eax,[ebp-4]` (a String Var).
'   The constructed TStadium is never stored anywhere by this function -- it is created,
'   populated and dropped; TStadium.New must be what registers it.

Function CreateStadium(a0:String)
	Local line:String = a0
	Local id:Int = NextFieldInt(line, "~t")
	If id < 1 Then Return 0
	Local s:TStadium = New TStadium
	s.id = id
	s.name = NextField(line, "~t")
	s.nation = NextFieldInt(line, "~t")
	s.capacity = NextFieldInt(line, "~t")
	s.longitude = Float(NextField(line, "~t"))
	s.latitude = Float(NextField(line, "~t"))
End Function
