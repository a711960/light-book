EnableExplicit

#TRACE_ENABLED = 1
#TRACE_FILENAME = "ExifComponent.dll"

;-- Error index
Enumeration
    #ERR_MBTOWC_FAILED   = 1
    #ERR_EXECUTE         = 2
    #ERR_ALLOCATE_MEMORY = 3
    #ERR_BUFFER_OVERFLOW = 4
    #ERR_NO_OUTPUT       = 5
    #ERR_PARSE_OUTPUT    = 6
    #ERR_ICU_OPEN        = 7
    #ERR_TIMEOUT         = 8
    #ERR_GETSPATH_FAILED = 9
    #ERR_WCTOMB_FAILED   = 10
EndEnumeration

;-- Includes
XIncludeFile "..\..\..\..\Common\include\ExtensionBase.pb"
XIncludeFile "..\..\..\..\Common\include\icuin.pbi"
XIncludeFile "..\..\..\..\Common\include\icuuc.pbi"
XIncludeFile "FileUtils.pb"


;-- Structure ExifParameters
Structure ExifParameters
  executable.s          ;path to exiftool.exe
  workingDir.s          ;process working directory
  parameters.s          ;exiftool parameters
  timeout.l             ;execution timeout
  maxOutput.l           ;buffer size
  ctx.l                 ;extension context
  code.l                ;request code
  List Files.s()        ;long filenames
  List FilesShort.s()   ;file short names
EndStructure


Procedure.l GetStdout(executable.s, parameters.s, workingDir.s, flags.l, maxOutput.l, timeout.l)
    Define program.i = RunProgram(executable, parameters, workingDir, flags)
    If program
        Define *stdout = AllocateMemory(maxOutput)
        
        If *stdout = 0
            KillProgram(program)
            CloseProgram(program)
            trace("AllocateMemory failed, killing exiftool")
            ProcedureReturn -#ERR_ALLOCATE_MEMORY
        EndIf
        
        Define offset.l, size.l
        
        Define StartTime.l = ElapsedMilliseconds()             
        
        While ProgramRunning(program)
          Sleep_(100)
          size = AvailableProgramOutput(program)
          If(size > 0 And offset + size <= maxOutput)
              ReadProgramData(program, *stdout + offset, size)
              offset = offset + size
          ElseIf (offset + size >= maxOutput)
              KillProgram(program)
              CloseProgram(program)
              FreeMemory(*stdout)
              trace("buffer overrun, killing exiftool")
              ProcedureReturn -#ERR_BUFFER_OVERFLOW
          EndIf
          
          If(timeout > 0 And ElapsedMilliseconds() - StartTime > timeout) 
              trace("timeout, killing exiftool")
              KillProgram(program)
              CloseProgram(program)
              FreeMemory(*stdout)
              ProcedureReturn -#ERR_TIMEOUT
          EndIf
        Wend
        
        trace("exitCode: " + Str(ProgramExitCode(program)))
        CloseProgram(program) ; Close the connection to the program
        
        If offset > 0
            Define *result = AllocateMemory(offset)
            If *result = 0
                FreeMemory(*stdout)
                ProcedureReturn -#ERR_ALLOCATE_MEMORY
            EndIf
            CopyMemory(*stdout, *result, offset)
            ProcedureReturn *result
        Else
          FreeMemory(*stdout)
          ProcedureReturn -#ERR_NO_OUTPUT
        EndIf
    Else
        ProcedureReturn -#ERR_EXECUTE
    EndIf
EndProcedure


Procedure.s ParseTags(*stdout, List Files.s(), List FilesShort.s(), *status.Long)
  Define i.l, m.l, prev.l, size.l, index.l, converted.l, name.s, value_size.l, keySize.l
  Define status.l, ucsd.l, ucsm.l, *name, line_begin.l, line.s, value_begin.l, key.s
  Define result.s = ""
  
  ucsd = ucsdet_open_49(@status)
  If ucsd <> 0
      size = MemorySize(*stdout)
      Define *target = AllocateMemory(4096)
      
      If *target = 0
          ucsdet_close_49(ucsd)
          trace("AllocateMemory failed")
          *status\l = #ERR_ALLOCATE_MEMORY
          ProcedureReturn ""
      EndIf
      
      For i = 1 To size - 1
        If(PeekB(*stdout + i - 1) = 13 And PeekB(*stdout + i) = 10)
           line_begin = *stdout + prev
           line = PeekS(line_begin, i - prev, #PB_Ascii)
           
           If FindString(line, "=====") > 0
               prev = i + 1
               Continue
           EndIf
           
           m = FindString(line, ":") - 1
           If(m = -1)
               prev = i + 1
               Continue
           EndIf
           
           value_begin = *stdout + (prev + m + 2)
           value_size = i - (prev + m + 1) - 2
           keySize = m 
           
           prev = i + 1
           
           ucsdet_setText_49(ucsd, value_begin, value_size, @status)
           If status <> 0
               Continue
           EndIf
           
           ucsm = ucsdet_detect_49(ucsd, @status)
           If ucsm = 0
               Continue
           EndIf
          
           *name = ucsdet_getName_49(ucsm, @status)
           
           name = PeekS(*name, -1, #PB_Ascii)
           
           ;this encoding create unrecoverable error in ICU
           If name = "IBM424_rtl" Or name = "IBM424_ltr"              
               *name = @"utf-8"
           EndIf

           converted = ucnv_convert_49(@"utf-8", *name, *target, 4096, value_begin, value_size, @status)
           If converted > 0
               key = Trim(PeekS(line_begin, keySize, #PB_Ascii))
               If(FindString(key, "ExifTool Version Number") Or FindString(key, "ExifToolVersion"))
                   SelectElement(Files(), index)
                   SelectElement(FilesShort(), index)
                   result = result + "FileNameOriginal" + #CR$ + Files() + #CR$ 
                   result = result + "MD5" + #CR$ + MD5FileFingerprint(FilesShort()) + #CR$  
                   index = index + 1
               EndIf
               result = result + key + #CR$ + PeekS(*target, converted, #PB_Ascii) + #CR$ 
           EndIf
       EndIf
      Next
      FreeMemory(*target)
      ucsdet_close_49(ucsd)
      If(Len(result) > 1)
          *status\l = 0
      Else
          *status\l = #ERR_PARSE_OUTPUT
      EndIf
      ProcedureReturn result
  Else
      *status\l = #ERR_ICU_OPEN
      ProcedureReturn ""
  EndIf
EndProcedure
  

Procedure RunExifTool(*params.ExifParameters)
    OnErrorCall(@ErrorHandler())
    
    Define parameters.s, i.l
    
    If Len(*params\parameters) > 1
        parameters = *params\parameters + " "
    Else
        parameters = ""
    EndIf
    
    For i = 0 To ListSize(*params\FilesShort()) - 1
        SelectElement(*params\FilesShort(), i)
        parameters = parameters + #DOUBLEQUOTE$ + *params\FilesShort() + #DOUBLEQUOTE$ + " "
    Next
    
    Define stdout.l = GetStdout(*params\executable, parameters, *params\workingDir, #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide, *params\maxOutput, *params\timeout)
    
    If stdout > 0
        Define status.l
        Define result.s = ParseTags(stdout, *params\Files(), *params\FilesShort(), @status)
        If (status = 0)
            DispatchEvent(*params\ctx, Str(*params\code), result)
        Else
            DispatchEvent(*params\ctx, Str(*params\code), "error: " + Str(status))
        EndIf
        FreeMemory(stdout)
    Else
        DispatchEvent(*params\ctx, Str(*params\code), "error: " + Str(-stdout))
    EndIf
    FreeMemory(*params)
EndProcedure



ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  OnErrorCall(@ErrorHandler())
    
  Define arraySize.l, i.l, longPath.s, shortPath.s, status.l

  Define *params.ExifParameters = AllocateMemory(SizeOf(ExifParameters))
  InitializeStructure(*params, ExifParameters)
  *params\ctx = ctx
  *params\code = GetArgInt32(0, argc, *argv)
  *params\maxOutput = GetArgInt32(1, argc, *argv)
  *params\timeout = GetArgInt32(2, argc, *argv)
  *params\executable = GetArgString(3, argc, *argv)
  *params\parameters = GetArgString(4, argc, *argv)
  *params\workingDir = GetArgString(5, argc, *argv)
  
  arraySize = GetArgArrayLen(6, argc, *argv)
  
  For i = 0 To arraySize - 1
      longPath = GetString(GetArgArrayItem(6, argc, *argv, i))
      shortPath = GetShortPathUTF8(@longPath, @status)
      If Len(shortPath) > 1
          If FileSize(shortPath) >= 0
              AddElement(*params\Files())
              *params\Files() = longPath
              
              AddElement(*params\FilesShort())
              *params\FilesShort() = shortPath
          ElseIf FileSize(longPath) >= 0
              trace("shortPath does not exist: '" + shortPath + "', using longPath instead=" + longPath)
              AddElement(*params\Files())
              *params\Files() = longPath
              
              AddElement(*params\FilesShort())
              *params\FilesShort() = longPath
          Else
               trace("longPath does not exist: " + longPath)
          EndIf
      EndIf
  Next
  
  CreateThread(@RunExifTool(), *params)
  
  ProcedureReturn 0
EndProcedure


ProcedureC.l GetShortPath(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  OnErrorCall(@ErrorHandler())  
    
  Define shortPath.s, status.l
  Define longPath.s = GetArgString(0, argc, *argv)
   
  shortPath = GetShortPathUTF8(@longPath, @status)
  
  If(status <> 0)
      ProcedureReturn GetNewStringUTF8("error: " + Str(status))
  EndIf    
 
  ProcedureReturn GetNewStringUTF8(shortPath)
EndProcedure


ProcedureC contextInitializer(extData.l, ctxType.s, ctx.l, *numFunctions.Long, *functions.Long)
  Define result.l
  
  ;exported extension functions count:
  Define size.l = 2 
  
  ;Array of FRENamedFunction:
  Dim f.FRENamedFunction(size - 1)
  
  ;there is no unsigned long type in PB
  setULong(*numFunctions, size)
  
  ;If you want to return a string out of a DLL, the string has to be declared as Global before using it.
  
  ;method name
  f(0)\name = AsciiAlloc("execute")
  ;function pointer
  f(0)\function = @Execute()
  
  f(1)\name = AsciiAlloc("GetShortPath")
  ;function pointer
  f(1)\function = @GetShortPath()
  
  *functions\l = @f()
EndProcedure

ProcedureC contextFinalizer(ctx.l)
EndProcedure 

ProcedureCDLL initializer(extData.l, *ctxInitializer.Long, *ctxFinalizer.Long)
  *ctxInitializer\l = @contextInitializer()
  *ctxFinalizer\l = @contextFinalizer()
EndProcedure 

;this method is never called on Windows...
ProcedureCDLL finalizer(extData.l)
EndProcedure 

; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 78
; FirstLine = 27
; Folding = --