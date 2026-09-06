' ZipRamStream.ZCreate -- VA 0x0058E861, 112 bytes   vtable slot 0xA8   sig (i,i,i):TRamStream
' byte-identical vs NSS5.exe (112/112, mode=reloc, 5 absolute-address slots masked)
' A TRamStream over a Byte array the stream itself owns: _data is allocated with
' _bbArrayNew1D (0x004A63D0) and TRamStream's _buf is pointed at its first element, which
' is the `lea eax,[eax+0x18]` at 0x0058E8B7 -- 0x18 is the BBArray header. The parent's
' field names are brl.ramstream's own: _pos, _size, _buf, _read, _write
' (tools/blitzmax-legacy-src/mod/brl.mod/ramstream.mod/ramstream.bmx:19).
' `s._buf = s._data` and `s._buf = Varptr s._data[0]` both reach MATCH; the plain
' assignment is kept as the simpler of the two.
' Parameter names are not recoverable from the binary and do not affect codegen.
	Function ZCreate:TRamStream(a0:Int, a1:Int, a2:Int)
		Local s:ZipRamStream = New ZipRamStream
		s._data = New Byte[a0]
		s._pos = 0
		s._size = a0
		s._buf = s._data
		s._read = a1
		s._write = a2
		Return s
	End Function
