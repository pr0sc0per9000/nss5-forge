' Fn_0058FD9E  --  zipengine module Function
' VA 0x0058FD9E   27 bytes
' byte-identical vs NSS5.exe (27/27, mode=reloc, reloc_masked=2, verified via try_function)
'
' UNCERTAIN: the original name. Module-level Functions carry no reflection record, so the
' name is ours to choose and has no effect on the emitted bytes; named by VA.
'
' WHAT IT IS: one of seven BlitzMax stand-ins for minizip's `zlib_filefunc_def` callback
' table -- open / read / write / tell / seek / close / testerror. Each one prints its own
' name and returns a neutral value; only the seek stub (Fn_0058FC5C) and the open stub
' (Fn_0058FB20) do any real work. This is the CLOSE slot: the string it prints, read out
' of NSS5.exe at 0x00C95F48, is "close".
'
' ALL SEVEN ARE DEAD IN THIS BUILD, and that is measured, not assumed: none of the seven
' addresses appears as the target of any call site in extracted/call_sites.tsv, and a
' search of the whole of NSS5.exe for each address as a little-endian dword finds ZERO
' occurrences -- so the `zlib_filefunc_def` table that would hold them is never built
' either. bcc emits every module-level Function whether or not anything reaches it, which
' is why they are in the image at all. That is also why the stubs' wrong return values
' (tell always 0, read/write always 0 bytes) never broke anything.
'
' UNCERTAIN: the arity. Nothing in the body touches a parameter, and a cdecl callee whose
' parameters are unread emits no bytes for them, so the declared arity cannot be recovered
' from the code. Written to minizip's `close_file_func(opaque, stream)` shape, which is
' what the callback table needs it to be.

Function Fn_0058FD9E:Int(a0:Byte Ptr, a1:Byte Ptr)
	Print "close"
End Function
