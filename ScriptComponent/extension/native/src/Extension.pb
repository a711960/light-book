EnableExplicit

#TRACE_ENABLED = 0
#TRACE_FILENAME = "ScriptComponent.dll"

;-- Error index
Enumeration
    #ERR_SUCCESS         = 0
    #ERR_SCRIPT_ERROR    = 1
    #ERR_CREATE_BSTR     = 2
    #ERR_CREATE_MSSC     = 3
    #ERR_CREATE_OBJ      = 4
EndEnumeration

;-- Includes
XIncludeFile "..\..\..\..\Common\include\ExtensionBase.pb"
XIncludeFile "ScriptControl.pb"
XIncludeFile "Object.pb"

;-- JSon parsers
DataSection
  jsonVBS : IncludeBinary "VbsJson.vbs" 
  Data.s Chr(0);null-terminator
  jsonJS  : IncludeBinary "JSJson.js"
  Data.s Chr(0);null-terminator
EndDataSection 


Structure ScriptParameters
  hwnd.l
  code.l
  vbs.l
  timeout.l
  jsonData.s
  script.s
  ctx.l
  allowUI.l
  safeSubset.l
EndStructure


; Returns Unicode JSON string
Procedure.s ExecuteScript(*params.ScriptParameters)
    
  OnErrorCall(@ErrorHandler())
  Define resultString.s
  
  ;Create Control
  Define *control.IScript = NewScript()
  If(*control = 0)
      ProcedureReturn ErrorJSON(#ERR_CREATE_MSSC, 0, 0, "Failed to create BSTR")
  EndIf

  Define jsonParser.s
  
  ;Set timeout
  *control\SetTimeOut(*params\timeout)
  
  ;Set allow UI
  *control\SetAllowUI(*params\allowUI)
  
  ;Set use safe subset
  *control\SetUseSafeSubset(*params\safeSubset)
  
  ;Set Script Language
  If(*params\vbs)
    *control\SetLanguage("VBScript")
    jsonParser = PeekS(?jsonVBS, -1, #PB_UTF16)
  Else
    *control\SetLanguage("JScript")
    jsonParser = PeekS(?jsonJS, -1, #PB_UTF16)
  EndIf
  
  Define *parameters.objObject, jsonData.s
  *parameters = NewObject()
  If(*parameters = 0)
      trace("Failed to create objObject");
      resultString = ErrorJSON(#ERR_CREATE_OBJ, 0, 0, "Failed to create BSTR")
  Else
      jsonData = Utf8ToUnicode(*params\jsonData)
      
      Define *arguments.VARIANT
      *arguments = AddMapElement(*parameters\Values(), "arguments")
      Define hRes.l = VariantInit_(*arguments)
      If #S_OK <> hRes
        trace("Failed to create BSTR");
        resultString = ErrorJSON(#ERR_CREATE_BSTR, 0, 0, "Failed to create BSTR")
      Else
        *arguments\vt = #VT_BSTR
        *arguments\bstrVal = T_BSTR(jsonData)
        *control\AddObject("parameters", *parameters)
        
        ;Add Script to Control
        Define r.l = *control\AddCode(jsonParser)
        If r <> #S_OK
          resultString = *control\GetError()
          trace("Failed to add json parser: " + resultString)
        Else
          If (*control\EvalLong("InitScript()") = 1)
            ;Add Script to Control
            r = *control\AddCode(Utf8ToUnicode(*params\script))
            If r <> #S_OK
              resultString = *control\GetError()
              trace("Failed to execute script")
            Else
              ;Get value of variable "result" 
              resultString.s = *control\EvalStr("result")
            EndIf
          Else
             trace("ScriptComponent InitScript() function failed")
             resultString = *control\GetError()
          EndIf
        EndIf
        VariantClear_(*arguments)
       EndIf 
   EndIf
  
  ;Destroy Control
  *control\Release()
  
  ProcedureReturn resultString
EndProcedure
 
 
Procedure RunScript(*params.ScriptParameters)
  Define result.s = ExecuteScript(*params)
  DispatchEventEx(*params\ctx, AsciiAlloc(Str(*params\code)), UnicodeToUtf8Alloc(result))
  FreeMemory(*params)
EndProcedure

 
;CDecl
ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  OnErrorCall(@ErrorHandler())  

  Define *params.ScriptParameters = AllocateMemory(SizeOf(ScriptParameters))
  *params\ctx = ctx
  *params\code = GetArgInt32(0, argc, *argv)
  *params\hwnd = 0 ;todo
  *params\script = GetArgString(7, argc, *argv)
  *params\jsonData = GetArgString(6, argc, *argv)
  *params\vbs = GetArgBool(2, argc, *argv)
  *params\timeout = GetArgInt32(3, argc, *argv)
  *params\allowUI = GetArgBool(4, argc, *argv)
  *params\safeSubset = GetArgBool(5, argc, *argv)
  
  Define resultString.s = ErrorJSON(#ERR_SUCCESS, 0, 0, "")
  
  If(GetArgBool(1, argc, *argv))
    CreateThread(@RunScript(), *params)
  Else
    resultString = ExecuteScript(*params)
  EndIf

  ProcedureReturn GetNewStringWC(resultString)
EndProcedure


;CDecl
ProcedureC contextInitializer(extData.l, ctxType.s, ctx.l, *numFunctions.Long, *functions.Long)
  Define result.l
  
  ;exported extension functions count:
  Define size.l = 1 
  
  ;Array of FRENamedFunction:
  Dim f.FRENamedFunction(size - 1)
  
  ;there is no unsigned long type in PB
  setULong(*numFunctions, size)
  
  ;If you want to return a string out of a DLL, the string has to be declared as Global before using it.
  
  ;method name
  f(0)\name = AsciiAlloc("execute")
  ;function pointer
  f(0)\function = @Execute()
  
  *functions\l = @f()
EndProcedure 


;CDecl
ProcedureC contextFinalizer(ctx.l)
EndProcedure 


;CDecl
ProcedureCDLL initializer(extData.l, *ctxInitializer.Long, *ctxFinalizer.Long)
  *ctxInitializer\l = @contextInitializer()
  *ctxFinalizer\l = @contextFinalizer()
EndProcedure 


;CDecl
;this method is never called on Windows...
ProcedureCDLL finalizer(extData.l)
EndProcedure 

; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 79
; FirstLine = 66
; Folding = --