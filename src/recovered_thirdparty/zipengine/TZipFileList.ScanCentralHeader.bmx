' TZipFileList.ScanCentralHeader -- VA 0x0058EB44, 385 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (385/385, mode=reloc, 19 absolute-address slots masked)
' Reads the local-file-header signature at offset 0, then walks BACKWARDS from EOF-4 one
' byte at a time looking for the end-of-central-directory signature $06054B50, takes the
' central-directory offset from +12 past it, and fills FileList by repeatedly calling
' SZIPCentralFileHeader.fill (slot 0x30) until it returns 0 or the stream ends.
'
' The two diagnostics are DebugLog, not Print. Print in this exe is 0x0059CC21 (see
' src/recovered_module/LogLine.bmx, byte-verified); these calls go to 0x005B9674, which is
' brl.blitz's DebugLog -- see the BRL_ALIAS_ADDITIONS block in scripts/helper_map.py for
' why the generated helper table did not name it and what that costs.
'
' `While True And Not Eof(zipFile)` is the original's condition, constant left operand and
' all: 0x0058EC94 materialises 1, tests it, and only then evaluates Eof, which is bcc's
' short-circuit And and cannot come from `While Not Eof(...)` alone.
' `While Not StreamPos(zipFile) = 0` parses as Not(pos = 0) -- sete then an inverted
' branch, 0x0058EC07.
	Method ScanCentralHeader:Int()
		SeekStream(zipFile, 0)
		If ReadInt(zipFile) <> $04034b50
			DebugLog "Invalid ZIP file!"
			Return 0
		EndIf
		Local centralOffset:Int = 0
		SeekStream(zipFile, StreamSize(zipFile) - 4)
		While Not StreamPos(zipFile) = 0
			If ReadInt(zipFile) = $06054b50
				SeekStream(zipFile, StreamPos(zipFile) + 12)
				centralOffset = ReadInt(zipFile)
				Exit
			EndIf
			SeekStream(zipFile, StreamPos(zipFile) - 5)
		Wend
		If centralOffset = 0
			DebugLog "unable to locate central directory!"
			Return 0
		EndIf
		SeekStream(zipFile, centralOffset)
		While True And Not Eof(zipFile)
			Local entry:SZipFileEntry = SZipFileEntry.Create()
			If entry.header.fill(zipFile)
				FileList.AddLast(entry)
				entry.zipFileName = entry.header.FileName
				extractFilename(entry)
			Else
				Exit
			EndIf
		Wend
		Return 1
	End Method
