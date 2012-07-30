EnableExplicit

XIncludeFile "..\..\..\..\Common\include\FlashRuntimeExtensions.pbi"

;-- Dll
ProcedureDLL AttachProcess(Instance)
  ;- This procedure is called once, when the program loads the library
  ;  for the first time. All init stuffs can be done here (but not DirectX init)
EndProcedure


ProcedureDLL DetachProcess(Instance)
  ;- Called when the program release (free) the DLL
EndProcedure


;- Both are called when a thread in a program call Or release (free) the DLL
ProcedureDLL AttachThread(Instance)
EndProcedure

ProcedureDLL DetachThread(Instance)
EndProcedure


;-- Debug
Procedure msg(message.s)
  Define filePath.s{1000}
  GetModuleFileName_(#Null, @filePath, 1000)
  Define path.s = GetPathPart(filePath) + #TRACE_FILENAME + ".log"
  Define file.l = OpenFile(#PB_Any, path)
  If file <> 0    ; opens an existing file or creates one, if it does not exist yet
    FileSeek(file, Lof(file))         ; jump to the end of the file (result of Lof() is used)
    WriteStringN(file, FormatDate("%dd.%mm.%yyyy %hh:%ii:%ss", Date())+ "  " + #TRACE_FILENAME + "  " + message)
    CloseFile(file)
  EndIf
EndProcedure

Macro trace(message)
  CompilerIf #TRACE_ENABLED
      msg(message);
  CompilerEndIf
EndMacro


;-- Error handling
Procedure.s GetErrorMessage()
   Define error.l,  err_msg$
   error = GetLastError_()
   err_msg$ = "no last error"
   If error
      Define *Memory, length.l
      *Memory = AllocateMemory(255)
      length = FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, #Null, error, 0, *Memory, 255, #Null)
      If length > 1 ; Some error messages are "" + Chr (13) + Chr (10)... stoopid M$... :(
         err_msg$ = PeekS(*Memory, length - 2)
      Else
      err_msg$ = ""
      EndIf
      FreeMemory(*Memory)
    EndIf
    ProcedureReturn err_msg$
EndProcedure 


;PB supports only unsigned byte (Ascii) and unsigned int (Unicode)
;unsigned long is not supported
;-- Unsigned

Procedure.q getULong(*source.Long)
   ;- Reads 4 bytes from the specified memory address,
   ;  and returns the value as *unsigned* integer
   ;  (minimum = 0, maximum = 4294967295).

   If *source\l < 0
      ProcedureReturn *source\l + $100000000
   Else
      ProcedureReturn *source\l
   EndIf
EndProcedure
 
Procedure setULong(*target.Long, source.q)
   ;- Writes an *unsigned* integer of 4 bytes size
   ;  to the specified memory address.

   If source >= 0 And source <= $FFFFFFFF
      If source > $7FFFFFFF
         *target\l = source - $100000000
      Else
         *target\l = source
      EndIf
   EndIf
EndProcedure

Procedure.q fromULong(source.l)
  ProcedureReturn getULong(@source)
EndProcedure
 
Procedure.l toULong(source.q)
  Define result.l
  setULong(@result, source)
  ProcedureReturn result
EndProcedure

;-- Unicode
#CP_UTF8 = 65001

Procedure.s Utf8ToUnicode(string.s)
  ;- Converts UCS2 to UTF8
  Define size.i, result.s
  size = MultiByteToWideChar_(#CP_UTF8, 0, @string, -1, 0, 0)
  result = Space(size * 2 + 1)
  MultiByteToWideChar_(#CP_UTF8, 0 , @string, -1, @result, size)
  ProcedureReturn result
EndProcedure

Procedure.s UnicodeToUtf8(string.s)
  ;- Converts UTF8 to UCS2
  Define size.i, result.s
  size = WideCharToMultiByte_(#CP_UTF8, 0, @string, -1, 0, 0, 0, 0)
  result = Space(size + 1)
  WideCharToMultiByte_(#CP_UTF8, 0 , @string, -1, @result, size, 0, 0)
  ProcedureReturn result
EndProcedure

; If you want to return a string out of a DLL, the string has to be declared as Global before using it.

Procedure.l AsciiAlloc(string.s)
  ;- Converts UCS2 to Ascii
  Define *result.Ascii = AllocateMemory(Len(string) + 1)
  PokeS(*result, string, -1, #PB_Ascii)
  ProcedureReturn *result
EndProcedure

Procedure.l UnicodeToUtf8Alloc(string.s)
  ;- Converts UTF8 to UCS2
  Define size.l = WideCharToMultiByte_(#CP_UTF8, 0, @string, -1, 0, 0, 0, 0)
  Define *result.Ascii = AllocateMemory(size)
  WideCharToMultiByte_(#CP_UTF8, 0 , @string, -1, *result, size, 0, 0)
  ProcedureReturn *result
EndProcedure



; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 25
; Folding = ---
; EnableXP