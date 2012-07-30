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
Procedure.s GetShortPathEx(*path.Ascii)

  Define result.l, size.i, pathSize.l, *longpath.Unicode, *shortpath.Unicode
    
  size = MultiByteToWideChar_(#CP_UTF8, 0, *path, -1, 0, 0)
  If(0 = size)
    ProcedureReturn ""
  EndIf
  
  *longpath.Unicode = AllocateMemory(size * 2)
  If(0 = *longpath)
    ProcedureReturn ""
  EndIf
  
  size = MultiByteToWideChar_(#CP_UTF8, 0 , *path, -1, *longpath, size)
  If(0 = size)
    FreeMemory(*longpath)
    ProcedureReturn ""
  EndIf
  
  pathSize = GetShortPathNameW(*longpath, #Null, 0)
  If(0 = pathSize)
    FreeMemory(*longpath)
    ProcedureReturn ""
  EndIf
  
  *shortpath = AllocateMemory(pathSize * 2 + 1)
  If(0 = *shortpath)
    FreeMemory(*longpath)
    ProcedureReturn ""
  EndIf
  
  pathSize = GetShortPathNameW(*longpath, *shortpath, size)
  If(0 = pathSize)
    FreeMemory(*longpath)
    FreeMemory(*shortpath)
    ProcedureReturn ""
  EndIf
  
  FreeMemory(*longpath)
    
  size = WideCharToMultiByte_(#CP_UTF8, 0, *shortpath, pathSize, 0, 0, 0, 0)
  If(0 = size)
    FreeMemory(*shortpath)
    ProcedureReturn ""
  EndIf

  Define *result = AllocateMemory(size)
  If(0 = *result)
    FreeMemory(*shortpath)
    ProcedureReturn ""
  EndIf
  
  If(0 = WideCharToMultiByte_(#CP_UTF8, 0 , *shortpath, pathSize, *result, size, 0, 0))
    FreeMemory(*shortpath)
    ProcedureReturn ""
  EndIf
    
  
  Define out.s = PeekS(*result, size, #PB_UTF8)
  FreeMemory(*result)
  
  ProcedureReturn out
EndProcedure

#FILE_ATTRIBUTE_DIRECTORY = $10
#INVALID_FILE_ATTRIBUTES = -1
Procedure.l DirExists(*file)
  Define ftyp.l = GetFileAttributes_(*file);
  If (ftyp = #INVALID_FILE_ATTRIBUTES)
      ProcedureReturn #False;  //something is wrong with your path!
  EndIf
  If (ftyp & #FILE_ATTRIBUTE_DIRECTORY)
      ProcedureReturn #True;   // this is a directory!
  EndIf
  ProcedureReturn #False;    // this is not a directory!
EndProcedure

; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 89
; FirstLine = 39
; Folding = -
; EnableXP