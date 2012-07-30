EnableExplicit

Import "Kernel32.lib"
  ;   DWORD WINAPI GetShortPathName(
  ;     __in   LPCTSTR lpszLongPath,
  ;     __out  LPTSTR lpszShortPath,
  ;     __in   DWORD cchBuffer
  ;   );
  GetShortPathNameW(path.l, shortpath.l, size.l)
EndImport


;CDecl
Procedure.s GetShortPathUTF8(*path.Ascii, *status.Long)

  Define result.l, size.i, pathSize.l, *longpath.Unicode, *shortpath.Unicode
    
  size = MultiByteToWideChar_(#CP_UTF8, 0, *path, -1, 0, 0)
  If(0 = size)
    *status\l = #ERR_MBTOWC_FAILED
    ProcedureReturn ""
  EndIf
  
  *longpath.Unicode = AllocateMemory(size * 2)
  If(0 = *longpath)
      *status\l = #ERR_ALLOCATE_MEMORY
      ProcedureReturn ""
  EndIf
  
  size = MultiByteToWideChar_(#CP_UTF8, 0 , *path, -1, *longpath, size)
  If(0 = size)
      FreeMemory(*longpath)
      *status\l = #ERR_MBTOWC_FAILED
      ProcedureReturn ""
  EndIf
  
  SetLastError_(#ERROR_SUCCESS)
  pathSize = GetShortPathNameW(*longpath, #Null, 0)
  If 0 = pathSize Or GetLastError_() <> #ERROR_SUCCESS
      FreeMemory(*longpath)
      trace("GetShortPathNameW GetLastError: " + GetErrorMessage())
      *status\l = #ERR_GETSPATH_FAILED
      ProcedureReturn ""
  EndIf
  
  *shortpath = AllocateMemory(pathSize * 2 + 1)
  If(0 = *shortpath)
      FreeMemory(*longpath)
      *status\l = #ERR_ALLOCATE_MEMORY
      ProcedureReturn ""
  EndIf
  
  pathSize = GetShortPathNameW(*longpath, *shortpath, size)
  If(0 = pathSize)
      FreeMemory(*longpath)
      FreeMemory(*shortpath)
      trace("GetShortPathNameW GetLastError: " + GetErrorMessage())
      *status\l = #ERR_GETSPATH_FAILED
      ProcedureReturn ""
  EndIf
  
  FreeMemory(*longpath)
    
  size = WideCharToMultiByte_(#CP_UTF8, 0, *shortpath, pathSize, 0, 0, 0, 0)
  If(0 = size)
      FreeMemory(*shortpath)
      *status\l = #ERR_WCTOMB_FAILED
      ProcedureReturn ""
  EndIf

  Define *result = AllocateMemory(size)
  If(0 = *result)
      FreeMemory(*shortpath)
      *status\l = #ERR_ALLOCATE_MEMORY
      ProcedureReturn ""
  EndIf
  
  If(0 = WideCharToMultiByte_(#CP_UTF8, 0 , *shortpath, pathSize, *result, size, 0, 0))
      FreeMemory(*shortpath)
      *status\l = #ERR_WCTOMB_FAILED
      ProcedureReturn ""
  EndIf
    
  
  Define out.s = PeekS(*result, size, #PB_UTF8)
  FreeMemory(*result)
  
  ProcedureReturn out
EndProcedure

; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 58
; FirstLine = 30
; Folding = -
; EnableXP