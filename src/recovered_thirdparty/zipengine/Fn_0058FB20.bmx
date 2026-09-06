' Fn_0058FB20  --  zipengine module Function
' VA 0x0058FB20   127 bytes
' byte-identical vs NSS5.exe (127/127, mode=reloc, reloc_masked=10, NSS5_NO_LEARN=1,
' verified via try_function)
'
' UNCERTAIN: the original name. Module-level Functions carry no reflection record.
'
' WHAT IT IS: the OPEN slot of the minizip `zlib_filefunc_def` callback set (the other
' six are Fn_0058FB9F read, Fn_0058FBE2 write, Fn_0058FC25 tell, Fn_0058FC5C seek,
' Fn_0058FD9E close, Fn_0058FDB9 testerror). With Fn_0058FC5C it is one of the two
' that do real work: it opens the named file as a BlitzMax stream, converts the object
' to an integer handle so the C side can carry it in a `voidpf`, and parks the stream in
' a module TMap so the
' handle can be turned back into an object later. Fn_0058FC5C is the other half of that
' arrangement.
'
' `RuntimeError`, NOT `DebugLog`. Both compile to `push <string>; call rel32; add esp,4`
' and are indistinguishable by shape. The original's target 0x005B963C is
' _brl_blitz_RuntimeError in extracted/brl_functions_inferred.tsv, and the oracle
' REFUSED to mask the operand while the body said DebugLog -- both sides resolved to a
' name and the names disagreed, which is compare()'s (a) rule doing exactly its job.
' 0x005B963C's own body corroborates it: it hands the message to bbExThrow (0x004A9320,
' named in TBitmapFont.Load.bmx), which DebugLog does not do.
'
' TWO SINGLE-WITNESS HELPER ROWS were bootstrapped for this body and the seek body and
' written to extracted/runtime_helpers.tsv:
'   0x004A90B0 _bbHandleFromObject   0x004A9170 _bbHandleToObject
' Each has exactly ONE call site in the whole of NSS5.exe (this body and Fn_0058FC5C
' respectively, per extracted/call_sites.tsv), so neither row can change the verdict of
' any other body. Both were learned by the oracle's own learn pass and the bodies then
' re-verified under NSS5_NO_LEARN=1, so the MATCH is decided by the table, not the learn.
'
' The `If s <> Null` is a direct compare-and-branch (`cmp esi,<null>; je`), not the
' setcc/movzx boolean the `If Not s` form produces -- compare Fn_0058FC5C, which has the
' other shape.
'
' UNCERTAIN: the Global's original name. It is the TMap at 0x00C95B90
' (extracted/globals_typed.tsv, stored from 0x0058DBD1); slot 0x38 on it is TMap.Insert.

'!Global g_zipfilefunc_streams:TMap

Function Fn_0058FB20:Int(a0:Byte Ptr, a1:Byte Ptr, a2:Int)
	RuntimeError "Experimental Code Called"
	Local s:TStream = OpenStream(String.FromCString(a1), 1, 1)
	If s <> Null
		Local h:Int = HandleFromObject(s)
		Print h
		g_zipfilefunc_streams.Insert(String(h), s)
		Return h
	End If
	Return 0
End Function
