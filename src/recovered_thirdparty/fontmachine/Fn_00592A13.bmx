' Fn_00592A13  --  fontmachine module Function
' VA 0x00592A13   36 bytes
' byte-identical vs NSS5.exe (36/36, mode=reloc, reloc_masked=1, verified via try_function)
'
' UNCERTAIN: the original name. Module-level Functions carry no reflection record, so the
' name is ours to choose and has no effect on the emitted bytes; named by VA, following
' Fn_00592B79.bmx.
'
' WHAT IT IS: a one-line wrapper over TDrawingPoint.Create. `call dword ptr [0x00C97EB8]`
' is TDrawingPoint's class table (0x00C97E88, extracted/class_tables.tsv) plus slot 0x30,
' which object_model.json gives as `Create (f,f):TDrawingPoint` -- a Type Function is
' dispatched through the class table exactly like a Method.
'
' Called by TDrawingPoint.Clone, by Fn_00592A37 (both exits) and by all three of
' TPrivateBitmapFont's Draw*Text bodies.

Function Fn_00592A13:TDrawingPoint(a0:Float, a1:Float)
	Return TDrawingPoint.Create(a0, a1)
End Function
