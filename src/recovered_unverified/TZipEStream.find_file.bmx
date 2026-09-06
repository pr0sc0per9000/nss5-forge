' TZipEStream.find_file  --  NOT VERIFIED, NOT BUILDABLE.  DO NOT ADD THE BYTE MARKER.
'
' 2026-08-23. THE BUILD NOW GETS A WORKING BODY FOR THIS SLOT FROM src/behaviour/
' TZipEStream.find_file.bmx -- not a reconstruction of the 309 bytes above (there will
' never be one; the callees are C), but a functional equivalent that decodes the entry in
' pure BlitzMax. This file stays exactly as it is: it is the record of what the ORIGINAL
' does and why it is unoracleable, and it is still 100% comments. Note that until
' assemble.py's tier guard was qualified, this note's mere existence emitted an empty stub
' for find_file AND blocked the behaviour body from filling it, which is half of why no
' save file in this project could ever be read back.
' VA 0x0058F882   309 bytes   vtable slot 0xA8   sig (i)i
' THIRD-PARTY MODULE (zipengine).
'
' THIS FILE IS DELIBERATELY 100% COMMENTS. assemble.py finds no statements in it and
' leaves the empty stub in place, which is what has to happen: the body below calls four
' minizip C functions that our BlitzMax toolchain does not ship, so emitting it as live
' code would make the assembled exe fail to link. Un-comment it only together with a real
' minizip.
'
' WHY IT CANNOT BE ORACLED
' ------------------------
' Four of its call operands go to minizip's own C code, statically linked into NSS5.exe
' below the reconstruction universe (the zipengine module block starts at 0x0058DBF3):
'
'   0x004023A0  unzLocateFile             (file, name, iCaseSensitivity)
'   0x00402FE0  unzOpenCurrentFilePassword(file, password)
'   0x00403000  unzOpenCurrentFile        (file)
'   0x00401580  a one-line wrapper: calls unzGetCurrentFileInfo(file,&info,0,0,0,0,0,0)
'               into a 0x58-byte stack struct and returns info.uncompressed_size (+0x1C)
'
' None of them is named on the original side (they are in neither
' extracted/brl_functions.tsv nor extracted/runtime_helpers.tsv), and none of them can be
' named on ours, because there is no minizip in tools/blitzmax-legacy-src to link against
' -- a `'!Raw Extern Function unzLocateFile...` block makes bcc emit `extrn _unzLocateFile`
' and ld then has nothing to resolve it with, so the probe does not even build. Both halves
' of harness.compare's by-name masking rule are therefore unavailable and the body is
' unverifiable as things stand. It is NOT a near miss: it has never been through the
' oracle at all.
'
' WHAT WOULD CLOSE IT: an object file (or import library) that defines the four symbols,
' plus a row for each original-side address, established the way the other C-runtime rows
' were. Everything else about the body is read straight off the disassembly and the field
' offsets are the same ones the six banked TZipEStream bodies use.
'
' The .ToCString() / MemFree pairs bracketing each call are NOT written in the source:
' they are what bcc emits by itself when a String is passed to an Extern parameter
' declared `$z`, which is how the Extern block must have been written.
'
' WHAT IT DOES: positions the underlying zip on this stream's entry. Looks the entry up by
' name (case-sensitively when case_sensitive is set, mode 1, otherwise mode 2), opens it
' with the password if there is one, records the entry's uncompressed size in file_size,
' and -- when a0 is set -- probes the entry by reading one byte and rewinding, so a
' corrupt or wrongly-passworded entry is rejected here rather than at the first Read.
' Every failure returns 0; success returns 1.
'
'	Method find_file:Int(a0:Int)
'		If reader.m_zipFile = Null Then Return 0
'		Local r:Int
'		If case_sensitive
'			r = unzLocateFile(reader.m_zipFile, filename, 1)
'		Else
'			r = unzLocateFile(reader.m_zipFile, filename, 2)
'		EndIf
'		If r <> 0 Then Return 0
'		If password.length
'			r = unzOpenCurrentFilePassword(reader.m_zipFile, password)
'		Else
'			r = unzOpenCurrentFile(reader.m_zipFile)
'		EndIf
'		If r <> 0 Then Return 0
'		file_size = unzGetCurrentFileSize(reader.m_zipFile)
'		If a0 And Seek(1) <> 1 Then Return 0
'		If a0 Then Seek(0)
'		Return 1
'	End Method
