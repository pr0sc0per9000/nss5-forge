' TZipEStream.Eof / Pos / Read  --  NOT VERIFIED, NOT BUILDABLE.  NO BYTE MARKER.
'
' 2026-08-23. Eof, Pos and Read are all supplied to the build now from src/behaviour/
' TZipEStream.{Eof,Pos,Read}.bmx -- functional equivalents, not reconstructions of the
' bytes above. This file stays as the record of what the original does. Note the filename
' trap it caused: assemble.py keys a file by <Type>.<Member>, so this one registered only
' as TZipEStream.Eof, and an empty stub was emitted for Eof alone while Pos and Read were
' free to be filled from a lower tier. That asymmetry is why Eof was the last one to be
' fixed and the easiest to miss.
' VA 0x0058F9B7  26 bytes  slot 0x30  ()i      Eof
' VA 0x0058F9D1  26 bytes  slot 0x34  ()i      Pos
' VA 0x0058FAE1  63 bytes  slot 0x48  (*b,i)i  Read
' THIRD-PARTY MODULE (zipengine). Three members in one file because they share one
' blocker and one sentence of explanation.
'
' THIS FILE IS DELIBERATELY 100% COMMENTS -- see TZipEStream.find_file.bmx for why.
'
' All three are one-liners over minizip C functions that are unnamed on the original side
' and unlinkable on ours, so none of them can reach the oracle:
'
'   0x00402880  unzeof(file)               returns UNZ_PARAMERROR (-102) on a null handle,
'                                          else pfile_in_zip_read->rest_read_uncompressed == 0
'   0x00402860  unztell(file)              same null guard, else ->stream.total_out (+0x18)
'   0x00402580  unzReadCurrentFile(file, buf, len)
'
' reader.m_zipFile is the raw minizip unzFile handle (ZipReader field at +0x10, typed
' Byte Ptr), which is why these go straight to C instead of through a BlitzMax stream.
'
' Read is the only one with any shape to it: it asks Eof() VIRTUALLY (class-table slot
' 0x30 on Self, not a direct call), and returns 0 without touching the zip once the entry
' is exhausted -- so a caller that keeps reading past the end gets zeroes, not an error.
' The `If Not Eof()` spelling is what produces the emitted `cmp eax,0 / jne` over the
' body; `If Eof() Then Return 0` would emit `je` and is not what the original does.
'
'	Method Eof:Int()
'		Return unzeof(reader.m_zipFile)
'	End Method
'
'	Method Pos:Int()
'		Return unztell(reader.m_zipFile)
'	End Method
'
'	Method Read:Int(a0:Byte Ptr, a1:Int)
'		If Not Eof()
'			Return unzReadCurrentFile(reader.m_zipFile, a0, a1)
'		EndIf
'		Return 0
'	End Method
