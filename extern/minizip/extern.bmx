' The minizip and ZipEngine glue declarations. Included, not Imported, so that the unit
' including it gets no extra init call: src/recovered_thirdparty/zipengine/unit/zipengine.bmx
' and minizip.bmx both Include it.
Extern
	Function unzOpen:Byte Ptr(path$z)
	Function unzClose:Int(file:Byte Ptr)
	Function unzLocateFile:Int(file:Byte Ptr, szFileName$z, iCaseSensitivity:Int)
	Function unzOpenCurrentFile:Int(file:Byte Ptr)
	Function unzOpenCurrentFilePassword:Int(file:Byte Ptr, password$z)
	Function unzReadCurrentFile:Int(file:Byte Ptr, buf:Byte Ptr, count:Int)
	Function unztell:Int(file:Byte Ptr)
	Function unzeof:Int(file:Byte Ptr)
	Function unzGetCurrentFileSize:Int(file:Byte Ptr)
	Function zipOpen:Byte Ptr(pathname$z, append:Int)
	Function zipOpenNewFileInZip:Int(file:Byte Ptr, filename$z, zipfi:Byte Ptr, extrafield_local:Byte Ptr, size_extrafield_local:Int, extrafield_global:Byte Ptr, size_extrafield_global:Int, comment:Byte Ptr, compmethod:Int, level:Int)
	Function zipOpenNewFileInZipPassword:Int(file:Byte Ptr, filename$z, zipfi:Byte Ptr, extrafield_local:Byte Ptr, size_extrafield_local:Int, extrafield_global:Byte Ptr, size_extrafield_global:Int, comment:Byte Ptr, compmethod:Int, level:Int, password$z)
	Function zipWriteInFileInZip:Int(file:Byte Ptr, buf:Byte Ptr, count:Int)
	Function zipClose:Int(file:Byte Ptr, global_comment$z)
	Function zipSetFileDate:Int(filename$z, hour:Int, minute:Int, sec:Int, mday:Int, mon:Int, year:Int)
End Extern
