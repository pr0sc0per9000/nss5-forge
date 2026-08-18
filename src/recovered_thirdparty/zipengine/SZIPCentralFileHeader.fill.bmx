' SZIPCentralFileHeader.fill
' VA 0x0058F1C9   625 bytes  mode=reloc  byte-identical vs NSS5.exe (625/625, length from Ghidra)
' KIND=Method (implicit Self at [ebp+8]), SIG (:brl.stream.TStream)i, class-table slot 0x30
' ASSUMPTIONS
'  * No module Globals are touched. Field names come from extracted/object_model.json.
'  * The stream calls resolve through alias sets in brl_functions.tsv, picked by context:
'      0x005B816F ReadInt   0x005B815A ReadShort   0x005B82B2 ReadString
'      0x005B80CE StreamPos 0x005B80F8 SeekStream
'  * `New tm` is the bbObjectNew(ClassTable_tm) at 0x0058F3A1; the refcount traffic around
'    every String/object store is inlined BBRETAIN/BBRELEASE and is not written in source.
'
' HARNESS NOTE -- READ THIS BEFORE RE-VERIFYING
'  harness.parse_sig_atom stops a ':' type name at the first '.', so this method's declared
'  parameter type ':brl.stream.TStream' decodes to Object followed by a run of bogus Int
'  parameters, and the probe fails to build with "Unable to convert from 'Object' to
'  'TStream'". Verified with a LOCAL monkeypatch (repo untouched) that takes the last dotted
'  component of a namespaced type name. The patch only fixes the probe's PARAMETER
'  DECLARATION; the 625 compared bytes are the real emitted body. Every game Type touched by
'  a namespaced BRL type in its signature is blocked the same way.
'
' CODEGEN NOTES
'  * The signature check is an early-return guard (`cmp / je body`), not an If/Else -- the
'    If/Else form emits `0F 85` and puts the success path first.
'  * tm_year masks before adding: ((date Shr 9) & $7F) + 1980. Without the mask the body is
'    3 bytes short and everything else still lines up.

	Method fill:Int(a0:TStream)
		Self.Sig = ReadInt(a0)
		If Self.Sig <> $02014b50
			SeekStream(a0, StreamPos(a0) - 4)
			Return 0
		End If
		Self.VersionMadeBy = ReadShort(a0)
		Self.VersionToExtract = ReadShort(a0)
		Self.GeneralBitFlag = ReadShort(a0)
		Self.CompressionMethod = ReadShort(a0)
		Self.LastModFileTime = ReadShort(a0)
		Self.LastModFileDate = ReadShort(a0)
		Self.DataDescriptor.fill(a0)
		Self.FilenameLength = ReadShort(a0)
		Self.ExtraFieldLength = ReadShort(a0)
		Self.CommentLength = ReadShort(a0)
		Self.DiskNumStart = ReadShort(a0)
		Self.InternalFileAttributes = ReadShort(a0)
		Self.ExternalFileAttributes = ReadInt(a0)
		Self.RelativeOffsetOfLocalHeader = ReadInt(a0)
		Self.FileName = ReadString(a0, Self.FilenameLength)
		Self.ExtraField = ReadString(a0, Self.ExtraFieldLength)
		Self.FileComment = ReadString(a0, Self.CommentLength)
		Self.LastModDateTime = New tm
		Self.LastModDateTime.tm_sec = (Self.LastModFileTime & $1f) Shl 1
		Self.LastModDateTime.tm_min = (Self.LastModFileTime Shr 5) & $3f
		Self.LastModDateTime.tm_hour = Self.LastModFileTime Shr 11
		Self.LastModDateTime.tm_mday = Self.LastModFileDate & $1f
		Self.LastModDateTime.tm_mon = (Self.LastModFileDate Shr 5) & $f
		Self.LastModDateTime.tm_year = ((Self.LastModFileDate Shr 9) & $7f) + 1980
		Return 1
	End Method
