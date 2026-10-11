' TZipEStream.find_file
' VA 0x0058F882   309 bytes   vtable slot 0xA8   sig (i)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (309/309, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' Three NESTED positive tests, each with its own failure `mov eax,0` parked at the end of
' the body in reverse order (0x0058F99B open failed, 0x0058F9A2 locate failed, 0x0058F9A9
' no handle). Guard-and-return-early spelling (`If ... = Null Then Return 0`) would put
' those inline instead, which is what the old recovered_unverified note got wrong.
' r is ONE register Local: both arms of each inner If/Else leave the call result in eax
' (`mov eax,ebx` at 0x0058F8C7 / 0x0058F8F4 / 0x0058F93F) and the merge tests eax
' directly. Uninitialised on purpose: `Local x:Int` emits no zero store (cf.
' TTeam.GetLosingBy, which merges two such Locals in eax/edx the same way).
' case_sensitive (+0xC) picks unzLocateFile mode 1 vs 2 (0x004023A0).
' Password test at 0x0058F902 is `cmp [password+8],0 / jne`: the FALL-THROUGH arm is
' 0x00403000 unzOpenCurrentFile, the jump target 0x00402FE0 unzOpenCurrentFilePassword,
' so the condition is password.length = 0 with the plain open first.
' 0x00401580 is the size glue (unzGetCurrentFileSize), stored to file_size (+0x14).
' a0 And Seek(1) <> 1 is the short-circuit at 0x0058F957..0x0058F975 (setne on the
' second half); Seek is slot 0x3C. `If a0 Then Seek(0)` re-reads [ebp+0xC] at 0x0058F981.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method find_file:Int(a0:Int)
		If reader.m_zipFile
			Local r:Int
			If case_sensitive
				r = unzLocateFile(reader.m_zipFile, filename, 1)
			Else
				r = unzLocateFile(reader.m_zipFile, filename, 2)
			EndIf
			If r = 0
				If password.length = 0
					r = unzOpenCurrentFile(reader.m_zipFile)
				Else
					r = unzOpenCurrentFilePassword(reader.m_zipFile, password)
				EndIf
				If r = 0
					file_size = unzGetCurrentFileSize(reader.m_zipFile)
					If a0 And Seek(1) <> 1 Then Return 0
					If a0 Then Seek(0)
					Return 1
				Else
					Return 0
				EndIf
			Else
				Return 0
			EndIf
		Else
			Return 0
		EndIf
	End Method
