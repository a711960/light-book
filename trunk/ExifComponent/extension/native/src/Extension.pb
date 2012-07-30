﻿EnableExplicit

#TRACE_ENABLED = 0
#TRACE_FILENAME = "ExifComponent.dll"

XIncludeFile "..\..\..\..\Common\include\ExtensionBase.pb"

XIncludeFile "..\..\..\..\Common\include\icuin.pbi"
XIncludeFile "..\..\..\..\Common\include\icuuc.pbi"
XIncludeFile "FileUtils.pb"

;-- Structure ExifParameters
Structure ExifParameters
  executable.s    ;path to exiftool.exe
  workingDir.s    ;process working directory
  parameters.s    ;exiftool parameters
  timeout.l       ;execution timeout
  maxOutput.l     ;buffer size
  ctx.l           ;extension context
  code.l          ;request code
  List Files.s()
  List FilesShort.s()
EndStructure


Procedure.l CreateErrorString(message.s)
    Define result.l, resultObject.l
    Define error.s = "error: " + message
    result = FRENewObjectFromUTF8(toULong(Len(error)), AsciiAlloc(error), @resultObject)
    ProcedureReturn resultObject
EndProcedure



Procedure.l GetStdout(executable.s, parameters.s, workingDir.s, flags.l, maxOutput.l)

  Define program.i = RunProgram(executable, parameters, workingDir, flags)
  If program
    Define *stdout = AllocateMemory(maxOutput)
    Define offset.l, size.l
    
    ;todo timeout
    
    While ProgramRunning(program)
      Sleep_(100)
      size = AvailableProgramOutput(program)
      If(size > 0 And offset + size <= maxOutput)
          ReadProgramData(program, *stdout + offset, size)
          offset = offset + size
      ElseIf (offset + size >= maxOutput)
          KillProgram(program)
          trace("kill program")
      EndIf
    Wend
    
    Define exitCode.l = ProgramExitCode(program)
    trace("exitCode: " + Str(exitCode))
    CloseProgram(program) ; Close the connection to the program
    
    If offset > 0
      Define *result = AllocateMemory(offset)
      CopyMemory(*stdout, *result, offset)
      FreeMemory(*stdout)
      ProcedureReturn *result
    Else
      FreeMemory(*stdout)
      ProcedureReturn 0
    EndIf
  Else
    ProcedureReturn 0
  EndIf
EndProcedure


Procedure.s ParseTags(*stdout, List Files.s(), List FilesShort.s())
  Define i.l, m.l, prev.l, size.l, index.l, converted.l, name.s, value_size.l, keySize.l
  Define status.l, ucsd.l, ucsm.l, *name, line_begin.l, line.s, value_begin.l, key.s
  Define result.s = ""
  
  ucsd = ucsdet_open_49(@status)
  
  If ucsd <> 0
      size = MemorySize(*stdout)
      Define *target = AllocateMemory(4096)
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
      trace(result)
      ProcedureReturn result
  Else
      ProcedureReturn ""
  EndIf
EndProcedure
  

Procedure RunExifTool(*params.ExifParameters)
    Define eventResult.l, parameters.s, i.l
    
    If Len(*params\parameters) > 1
        parameters = *params\parameters + " "
    Else
        parameters = ""
    EndIf
    
    For i = 0 To ListSize(*params\FilesShort()) - 1
        SelectElement(*params\FilesShort(), i)
        parameters = parameters + #DOUBLEQUOTE$ + *params\FilesShort() + #DOUBLEQUOTE$ + " "
    Next
    
    Define stdout.l = GetStdout(*params\executable, parameters, *params\workingDir, #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide, *params\maxOutput)
    
    If stdout
        Define result.s = ParseTags(stdout, *params\Files(), *params\FilesShort())
        If Len(result) > 1
            eventResult = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc(result))
            trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
        Else
            eventResult = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc("error: failed to extract metadata"))
            trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
        EndIf
        FreeMemory(stdout)
    Else
        eventResult = FREDispatchStatusEventAsync(*params\ctx, AsciiAlloc(Str(*params\code)), AsciiAlloc("error: execution failed"))
        trace (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
    EndIf
    FreeMemory(*params)
EndProcedure



ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  trace("Invoked Execute, args size:" + Str(fromULong(argc)))

  Define result.l, length.l, maxOutput.l, parameters.s, *string.Ascii, code.l, executable.s, timeout.l, workingDir.s, arraySize.l, i.l, element.l, file.s
  
  result = FREGetObjectAsInt32(*argv\object[0], @code)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsInt32(*argv\object[1], @maxOutput)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsInt32(*argv\object[2], @timeout)
  trace("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsUTF8(*argv\object[3], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  executable = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[4], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  parameters = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[5], @length, @*string)
  trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  workingDir = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetArrayLength(*argv\object[6], @arraySize)
  trace("result=" + ResultDescription(result, "FREGetArrayLength"))
  
  trace("Argument: code=" + Str(code))
  trace("Argument: maxOutput=" + Str(maxOutput))
  trace("Argument: timeout=" + Str(timeout))
  trace("Argument: executable=" + executable)
  trace("Argument: parameters=" + parameters)
  trace("Argument: workingDir=" + workingDir)
  trace("Argument: arraySize=" + Str(arraySize))
  
  
  Define *params.ExifParameters = AllocateMemory(SizeOf(ExifParameters))
  InitializeStructure(*params, ExifParameters)
  *params\ctx = ctx
  *params\code = code
  *params\executable = executable
  *params\parameters = parameters
  *params\workingDir = workingDir
  *params\maxOutput = maxOutput
  
  For i = 0 To arraySize - 1
      result = FREGetArrayElementAt(*argv\object[6], i, @element)
      ;trace("result=" + ResultDescription(result, "FREGetArrayElementAt"))
      
      result = FREGetObjectAsUTF8(element, @length, @*string)
      ;trace("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
      file = GetShortPathUTF8(*string)
     
      If Len(file) > 1
          If Not DirExists(@file)
              ;trace(PeekS(*string, fromULong(length) + 1) + " ==> " + file)
            
              AddElement(*params\Files())
              *params\Files() = PeekS(*string, fromULong(length) + 1)
              
              AddElement(*params\FilesShort())
              *params\FilesShort() = file
          Else
              trace("file is directory: " + file)
          EndIf
      EndIf
  Next
  
  CreateThread(@RunExifTool(), *params)
  
  Define resultObject.l
 
  result = FRENewObjectFromBool(toULong(1), @resultObject)
  trace(ResultDescription(result, "FRENewObjectFromBool"))
  
  ProcedureReturn resultObject
EndProcedure


ProcedureC.l GetShortPath(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  trace("Invoked GetShortPath, args size:" + Str(fromULong(argc)))
  
  Define length.l, *path.Ascii, result.l, path.s, resultObject.l
  
  result = FREGetObjectAsUTF8(*argv\object[0], @length, @*path)
  If(result <> #FRE_OK)
    ProcedureReturn CreateErrorString(ResultDescription(result, "FREGetObjectAsUTF8"))
  EndIf
   
  path = GetShortPathUTF8(*path)
  
  If(Len(path) = 1)
      ProcedureReturn CreateErrorString("GetShortPathEx failed")
  EndIf    
  
  result = FRENewObjectFromUTF8(toULong(Len(path)), @path, @resultObject)
  If(result <> #FRE_OK)
    ProcedureReturn CreateErrorString(ResultDescription(result, "FREGetObjectAsUTF8"))
  EndIf
  
  ProcedureReturn resultObject
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
; CursorPosition = 185
; FirstLine = 11
; Folding = --