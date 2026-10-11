' ZipReader.ExtractFileToDisk
' VA 0x0058E634   395 bytes   vtable slot 0x54   sig ($,$,i,$)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (395/395, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a0 entry name, a1 destination path, a2 case flag, a3 password. Frame sub esp,0xC:
' [ebp-4] ret (explicit `= 0` store at 0x0058E643, before the lookup), [ebp-8] entry
' (getFileInfoByName, slot 0x48), [ebp-0xC] the "stamp the date" flag (its `= 0` store at
' 0x0058E659 comes AFTER the lookup, so it is declared after entry).
' entry.IsDirectory() is SZipFileEntry slot 0x34. Directory arm: FileType(a1)=0 ->
' ret = CreateDir(a1,1), flag=1; else ret=1 (inner If/Else, end-of-then jmp 0x0058E698).
' File arm: FileType(ExtractDir(a1))=0 -> CreateDir(ExtractDir(a1),1) (no Else);
' WriteFile(a1) -> ebx; `cmp ebx,Null / je` is the direct-compare `<> Null` shape;
' ExtractFile(a0,a2,a3) is slot 0x50 -> edx; the And at 0x0058E6FE is the setne/movzx
' boolean form over both objects; CopyStream(src, dst, 0x1000); CloseFile(dst) is the
' 0x005B812B CloseFile/CloseStream alias row; ret=1, flag=1.
' Date stamp: ToCString(a1) first, then entry.header(+0x14).LastModDateTime(+0x3C) re-read
' per argument, pushed tm +0x1C,+0x18,+0x14,+0x08,+0x0C,+0x10, i.e. the call is
' (path, hour, min, sec, mday, mon, year) -> glue 0x00401510 (our name zipSetFileDate).
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method ExtractFileToDisk:Int(a0:String, a1:String, a2:Int, a3:String)
		Local ret:Int = 0
		Local entry:SZipFileEntry = getFileInfoByName(a0)
		Local stamp:Int = 0
		If entry.IsDirectory()
			If FileType(a1) = 0
				ret = CreateDir(a1, 1)
				stamp = 1
			Else
				ret = 1
			EndIf
		Else
			If FileType(ExtractDir(a1)) = 0 Then CreateDir(ExtractDir(a1), 1)
			Local dst:TStream = WriteFile(a1)
			If dst <> Null
				Local src:TRamStream = ExtractFile(a0, a2, a3)
				If dst <> Null And src <> Null Then CopyStream(src, dst, 4096)
				CloseFile(dst)
				ret = 1
				stamp = 1
			EndIf
		EndIf
		If stamp
			zipSetFileDate(a1, entry.header.LastModDateTime.tm_hour, entry.header.LastModDateTime.tm_min, entry.header.LastModDateTime.tm_sec, entry.header.LastModDateTime.tm_mday, entry.header.LastModDateTime.tm_mon, entry.header.LastModDateTime.tm_year)
		EndIf
		Return ret
	End Method
