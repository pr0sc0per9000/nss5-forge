' Fn_00592967  --  fontmachine module Function
' VA 0x00592967   54 bytes
' byte-identical vs NSS5.exe (54/54, mode=reloc, reloc_masked=1, verified via try_function)
'
' UNCERTAIN: the original name. Module-level Functions carry no reflection record, so the
' name is ours to choose and has no effect on the emitted bytes; named by VA, following
' Fn_00592A13.bmx.
'
' WHAT IT IS: the TRectangle twin of Fn_00592A13 -- a one-line wrapper over
' TRectangle.Create. `call dword ptr [0x00C97DE0]` is TRectangle's class table
' (0x00C97DB0, extracted/class_tables.tsv) plus slot 0x30, which object_model.json gives
' as `Create (f,f,f,f):TRectangle`; a Type Function dispatches through the class table
' exactly like a Method.
'
' Its only caller is TRectangle.Clone.

Function Fn_00592967:TRectangle(a0:Float, a1:Float, a2:Float, a3:Float)
	Return TRectangle.Create(a0, a1, a2, a3)
End Function
