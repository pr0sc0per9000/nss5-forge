' TTrainingObject.RenderAll
' VA 0x00582da9   121 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory, mode=reloc)
' KIND=Function -- static, no implicit Self.
' assumptions: module Global 0x00c6d568 is :TList (globals_final has it untyped as Object;
'              it is walked with ObjectEnumerator/HasNext/NextObject, so it is a TList);
'              the downcast class table 0x00c6d678 is TTrainingObject;
'              TTrainingObject slot 0x3c = Render().
'
' The guard must be `If Not g Then Return 0`, not `If g = Null Then Return 0`.
' `= Null` lets bcc fold the compare into the branch (`cmp dword [g], bbNullObject`,
' 10 bytes); `Not <object>` forces the object to be coerced to Int first
' (`mov eax,[g] / cmp eax,bbNullObject / setne al / movzx eax,al / cmp eax,0 / jne`,
' 21 bytes) with the branch sense inverted. That 9-byte difference is the whole gap.
	Function RenderAll:Int()
		'!Global g_trainobjs:TList
		If Not g_trainobjs Then Return 0
		For Local o:TTrainingObject = EachIn g_trainobjs
			o.Render()
		Next
	End Function
