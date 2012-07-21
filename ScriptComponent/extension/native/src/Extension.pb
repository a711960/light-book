EnableExplicit

;#LOG_FILE = "C:\pureair.log"

XIncludeFile "Unsigned.pb"
XIncludeFile "Unicode.pb"
XIncludeFile "Logger.pb"
XIncludeFile "FlashRuntimeExtensions.pbi"
XIncludeFile "ScriptControl.pb"
XIncludeFile "Object.pb"

Global *log.Logger

ProcedureDLL AttachProcess(Instance)
  ;- This procedure is called once, when the program loads the library
  ;  for the first time. All init stuffs can be done here (but not DirectX init)
  Define processID.l = GetCurrentProcessId_()
  
  *log = New_Logger("ScriptComponent.dll")
  
  *log\info(#CRLF$)
  *log\info(#CRLF$)
  *log\info("----------------------------------------------------------------")
  *log\info("AttachProcess: " + Str(processID) + ", instance = " + Str(Instance))
EndProcedure


ProcedureDLL DetachProcess(Instance)
  ;- Called when the program release (free) the DLL
  *log\info("DetachProcess: " + Str(Instance))
  *log\info("----------------------------------------------------------------")
  FreeMemory(*log)
EndProcedure


;- Both are called when a thread in a program call Or release (free) the DLL
ProcedureDLL AttachThread(Instance)
  *log\Debug("AttachThread: " + Str(Instance))
EndProcedure


ProcedureDLL DetachThread(Instance)
  *log\Debug("DetachThread: " + Str(Instance))
EndProcedure


Procedure LogError()
   Define error.l
   error = GetLastError_()
   If error
      Define *Memory, length.l, err_msg$
      *Memory = AllocateMemory(255)
      length = FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, #Null, error, 0, *Memory, 255, #Null)
      If length > 1 ; Some error messages are "" + Chr (13) + Chr (10)... stoopid M$... :(
         err_msg$ = PeekS(*Memory, length - 2)
      Else
         err_msg$ = "Unknown error!"
      EndIf
      FreeMemory(*Memory)
      *log\error(err_msg$)
   EndIf
EndProcedure 

Structure ExecuteParameters
  jsonInjectData.s
  jsonParameters.s
  hwnd.l
  ctx.l
  code.l
EndStructure

Procedure ErrorHandler()
   MessageRequester("OnError test", "The following error happened: " + ErrorMessage())
EndProcedure
 
Procedure RunScript(*params.ExecuteParameters)
  
  OnErrorCall(@ErrorHandler())
  
  ;Create Control
  InitScriptControl()
  
  Define *my.objObject = NewObject(?VT_Object)
  
  ;Add some tags
  *my\Values("Zahl")\vt = #VT_R8
  *my\Values()\dblVal = 100.95
  
 
  ;Script
  Define vbs.s
  vbs = "Dim name, value" + #CRLF$
  vbs + "name = 'VB-Zahl'" + #CRLF$
  vbs + "my.items(name) = 20" + #CRLF$
  vbs + "my.items('Text') = 'Hallo Welt'" + #CRLF$
  vbs + "value = My.items('Zahl')" + #CRLF$
  vbs + "MsgBox 'Value = ' & value"
  vbs = ReplaceString(vbs, "'", #DOUBLEQUOTE$)
  
  ;Set Script Language
  SCtr_SetLanguage("VBScript")
  
  ;Set timeout
  SCtr_SetTimeOut(10000)
  
  ;Add Object from data section (VT_Object) with alias "My"
  SCtr_AddObject("my", *my)
  
  ;Add Script to Control
  Define r1.l = SCtr_AddCode(vbs)
  If r1 <> #S_OK
    *log\error(SCtr_GetError())
  EndIf
  
  ;Get value of variable "value" 
  Define result.d = SCtr_EvalDouble("value")
  *log\info("value = " + StrD(result))
  
  ;Check map
  ForEach *my\Values()
    *log\info("Map(" + MapKey(*my\Values()) + "): " + VT_STR(*my\Values()))
  Next
  
  ;Destroy Control
  DeleteScriptControl()
   
  Define eventResult.l = FREDispatchStatusEventAsync(*params\ctx, asGlobal(Str(*params\code)), asGlobal(StrD(result)))
  *log\Debug (ResultDescription(eventResult, "FREDispatchStatusEventAsync"))
EndProcedure

 

;CDecl
ProcedureC.l Execute(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  *log\info("Invoked Execute")
  
  Define result.l
  
  *log\info("Method args size: " + Str(fromULong(argc)))

  Define resultObject.l, length.l, async.l, jsonParameters.s, jsonInjectData.s, *string.Ascii, code.l
  
  result = FREGetObjectAsInt32(*argv\object[0], @code)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsBool(*argv\object[1], @async)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsBool"))
  
  result = FREGetObjectAsUTF8(*argv\object[2], @length, @*string)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  jsonParameters = PeekS(*string, fromULong(length) + 1)
  
  result = FREGetObjectAsUTF8(*argv\object[3], @length, @*string)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  jsonInjectData = PeekS(*string, fromULong(length) + 1)
  
  *log\info("Argument: code=" + Str(code))
  *log\info("Argument: async=" + Str(fromULong(async)))
  *log\info("Argument: jsonParameters=" + Utf8ToUnicode(jsonParameters))
  *log\info("Argument: jsonInjectData=" + Utf8ToUnicode(jsonInjectData))
  
  
   Define *params.ExecuteParameters = AllocateMemory(SizeOf(ExecuteParameters))
   *params\ctx = ctx
   *params\code = code
   *params\hwnd = 0 ;todo
   *params\jsonParameters = jsonParameters
   *params\jsonInjectData = jsonInjectData
   
   If(async)
     *log\info("execute async")
     CreateThread(@RunScript(), *params)
   Else
     *log\info("execute sync")
     RunScript(*params)
   EndIf
  
   ;return Boolean.TRUE
   result = FRENewObjectFromBool(toULong(1), @resultObject)
   *log\Debug(ResultDescription(result, "FRENewObjectFromBool"))
  
   ProcedureReturn resultObject
EndProcedure


;CDecl
ProcedureC contextInitializer(extData.l, ctxType.s, ctx.l, *numFunctions.Long, *functions.Long)
  *log\info("create context: " + Str(ctx) + "=" + Utf8ToUnicode(ctxType))
  
  Define result.l
  
  ;exported extension functions count:
  Define size.l = 1 
  
  ;Array of FRENamedFunction:
  Dim f.FRENamedFunction(size - 1)
  
  ;there is no unsigned long type in PB
  setULong(*numFunctions, size)
  
  ;If you want to return a string out of a DLL, the string has to be declared as Global before using it.
  
  ;method name
  f(0)\name = asGlobal("execute")
  ;function pointer
  f(0)\function = @Execute()
  
  *functions\l = @f()
  
  *log\info("create context complete");
EndProcedure 


;CDecl
ProcedureC contextFinalizer(ctx.l)
  *log\info("dispose context: " + Str(ctx))
EndProcedure 


;CDecl
ProcedureCDLL initializer(extData.l, *ctxInitializer.Long, *ctxFinalizer.Long)
  *ctxInitializer\l = @contextInitializer()
  *ctxFinalizer\l = @contextFinalizer()
EndProcedure 


;CDecl
;this method is never called on Windows...
ProcedureCDLL finalizer(extData.l)
  ;do nothing
EndProcedure 
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 88
; FirstLine = 79
; Folding = ---