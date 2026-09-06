' Fn_00591106  --  fontmachine module Function
' VA 0x00591106   376 bytes
' byte-identical vs NSS5.exe (376/376, mode=reloc, reloc_masked=25, NSS5_NO_LEARN=1,
' verified via try_function)
'
' UNCERTAIN: the original name. Module-level Functions carry no reflection record, so the
' name is ours to choose; named by VA, following Fn_00592A13.bmx.
'
' WHAT IT IS: the module's guarded DrawText wrapper. It refuses a null font and it turns
' anything thrown out of TBitmapFont.DrawText into a TDrawTextException carrying the
' original exception's type name and text.
'
' Both messages are read out of NSS5.exe, not written from memory -- the misspelling in
' "becouse" (0x00C976E0) and the trailing space in "... source is: " (0x00C9775C) are the
' original's own bytes.
'
' `TTypeId.ForObject(ex).Name()` is `call dword ptr [0x00C98A20]`, which is TTypeId's class
' table (0x00C989A0, extracted/class_tables.tsv) plus slot 0x80, then slot 0x30 on the
' TTypeId it returns. The oracle resolves that operand to (Type, slot) on BOTH sides and
' requires them to agree, so the pair is proved, not assumed.
'
' THE `Return 0` AFTER THE `Throw` IS LOAD-BEARING and is not dead-code tidying. Without
' it the If has to be written with an Else, and bcc then ends the first arm with a bare
' `jmp` to the merge point instead of the original's `mov eax,0; jmp <epilogue>`; the body
' comes out 371 bytes against 376 and every branch displacement after it shifts. The
' original really does set the return value and leave.
'
' `Catch ex:Object` -- the handler downcasts the thrown value to Object
' (`bbObjectDowncast(ex, 0x005C9CA0)`) and rethrows if that fails, which is the Object
' catch-all shape. The Offending field is left at the Null that TPrivateException.New
' gives it; only the null-font arm assigns it, and there it assigns Null explicitly.
'
' TWO HELPER ROWS were bootstrapped for this body and written to
' extracted/runtime_helpers.tsv: 0x004A9280 _bbExEnter and 0x004A93C0 _bbExLeave, the
' Try/Catch frame pair. All eight callers of each in NSS5.exe are outside src/recovered/
' (they are BRL-region functions plus this one, per extracted/call_sites.tsv), so neither
' row can change the verdict of any body in the game corpus. Both were learned by the
' oracle's own learn pass and this body then re-verified under NSS5_NO_LEARN=1.

Function Fn_00591106:Int(a0:TBitmapFont, a1:String, a2:Int, a3:Int, a4:Int)
	If a0 = Null
		Local e:TDrawTextException = New TDrawTextException
		e.PrivateData.Description = "Can't draw text becouse the bitmapfont is null."
		e.PrivateData.Offending = Null
		Throw e
		Return 0
	End If
	Try
		a0.DrawText(a1, a2, a3, a4)
	Catch ex:Object
		Local e2:TDrawTextException = New TDrawTextException
		e2.PrivateData.Description = "There was an unhandled exception inside this drawtext operation. The exception source is: " + TTypeId.ForObject(ex).Name() + ":" + ex.ToString()
		Throw e2
	End Try
End Function
