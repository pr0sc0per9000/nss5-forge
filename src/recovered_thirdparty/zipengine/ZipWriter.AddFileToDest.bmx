' ZipWriter.AddFileToDest
' VA 0x0058DEE6   584 bytes   vtable slot 0x58   sig ($,$,$)i
' THIRD-PARTY MODULE (zipengine). Calls minizip 1.01e through extern/minizip.
' byte-identical vs NSS5.exe (584/584, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a0 file on disk, a1 name inside the zip, a2 password. Both guards jump to the one
' implicit `mov eax,0` at 0x0058E120, so two plain nested Ifs, no Else.
' OpenFile(a0,1,1) = brl.filesystem OpenFile with its defaults (0x005B6584); `cmp
' [ebp-0xC],Null / je` is the direct-compare `<> Null`. StreamSize 0x005B80E3 -> [ebp-0x10].
' FileTime(a0) -> [ebp-4] (address taken: `lea eax,[ebp-4]`), 0x004A4520 is pub.stdc's
' localtime_ (a jmp to the msvcrt localtime thunk 0x004B4728); its struct tm pointer
' stays in esi and is read as Ints +0..+0x14, year +0x76C (1900) at 0x0058DF87.
' New zip_fileinfo lives only in eax (no call until getBank, slot 0x30) -> bank in edi.
' Password test at 0x0058DF9E: cmp [a2+8],0 / jne. Plain arm calls 0x00404A00 =
' zipOpenNewFileInZip (10 args, add esp,0x28; it forwards to zipOpenNewFileInZip2
' 0x004049B0), NOT zipOpenNewFileInZip3. Password arm calls glue 0x004015B0 (11 args,
' add esp,0x2C; our name zipOpenNewFileInZipPassword). Args: m_zipFile, a1$z,
' BankBuf(bank) (0x005B6E24), 0,0,0,0,0, 8 (Z_DEFLATED), m_compressionLevel (+0x14)
' [, a2$z]. BankBuf is evaluated AFTER the ToCString(s), inline in the pushes.
' LoadByteArray (0x005B8488) -> [ebp-8]; 0x00403D60 = zipWriteInFileInZip(m_zipFile,
' data (lea +0x18), size). NO zipCloseFileInZip and NO CloseFile here: the original
' leaves both open (minizip closes the open entry on the next zipOpenNewFileInZip* or
' zipClose).
' SZipFileEntry.Create via class table +0x30 (call [0x00C95874]) -> ebx; zipFileName,
' simpleFileName (StripDir), path (ExtractDir) are all from a0, not a1.
' `If Not m_zipFileList` is the setne/movzx/cmp/jne shape at 0x0058E0D1, not `= Null`.
' TList slot 0x44 is AddLast.
'!Import "<repo>/extern/minizip/minizip.bmx"
	Method AddFileToDest:Int(a0:String, a1:String, a2:String)
		If m_zipFile
			Local src:TStream = OpenFile(a0)
			If src <> Null
				Local size:Int = StreamSize(src)
				Local ftime:Int = FileTime(a0)
				Local t:Int Ptr = Int Ptr(localtime_(Varptr ftime))
				Local zfi:zip_fileinfo = New zip_fileinfo
				zfi.tmz_date.tm_sec = t[0]
				zfi.tmz_date.tm_min = t[1]
				zfi.tmz_date.tm_hour = t[2]
				zfi.tmz_date.tm_mday = t[3]
				zfi.tmz_date.tm_mon = t[4]
				zfi.tmz_date.tm_year = t[5] + 1900
				Local bank:TBank = zfi.getBank()
				If a2.length = 0
					zipOpenNewFileInZip(m_zipFile, a1, BankBuf(bank), Null, 0, Null, 0, Null, 8, m_compressionLevel)
				Else
					zipOpenNewFileInZipPassword(m_zipFile, a1, BankBuf(bank), Null, 0, Null, 0, Null, 8, m_compressionLevel, a2)
				EndIf
				Local data:Byte[] = LoadByteArray(src)
				zipWriteInFileInZip(m_zipFile, data, size)
				Local entry:SZipFileEntry = SZipFileEntry.Create()
				entry.zipFileName = a0
				entry.simpleFileName = StripDir(a0)
				entry.path = ExtractDir(a0)
				If Not m_zipFileList Then m_zipFileList = New TZipFileList
				m_zipFileList.FileList.AddLast(entry)
			EndIf
		EndIf
	End Method
