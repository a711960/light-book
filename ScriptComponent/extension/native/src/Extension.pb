EnableExplicit

;#LOG_FILE = "C:\pureair.log"

XIncludeFile "Unsigned.pb"
XIncludeFile "Unicode.pb"
XIncludeFile "Logger.pb"
XIncludeFile "FlashRuntimeExtensions.pb"

Global *log.Logger



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

Structure MessageParameters
  text.s
  title.s
  dwFlags.l
  ctx.l
EndStructure

ProcedureDLL AttachProcess(Instance)
  ;- This procedure is called once, when the program loads the library
  ;  for the first time. All init stuffs can be done here (but not DirectX init)
  Define processID.l = GetCurrentProcessId_()
  
  *log = New_Logger("pureair.dll")
  
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


Procedure ModalMessage(*params.MessageParameters)
  Define result.l, code.l
  code = MessageRequester(*params\title, *params\text, *params\dwFlags)
  result = FREDispatchStatusEventAsync(*params\ctx, asGlobal("showDialog"), asGlobal(Str(code)))
  *log\Debug (ResultDescription(result, "FREDispatchStatusEventAsync"))
EndProcedure


Procedure ErrorHandler()
   MessageRequester("OnError test", "The following error happened: " + ErrorMessage())
EndProcedure

Structure ResultData
    resultType.l
    sResult.s
    nResult.l
EndStructure
 
   
Prototype.l DllGetClassObject(*rclsid.GUID, *riid.GUID, *ppv.Long)
Prototype.l Decrement(value.l)

;CDecl
ProcedureC.l showDialog(ctx.l, funcData.l, argc.l, *argv.FREObjectArray)
  *log\info("Invoked showDialog")
  
  Define result.l
  
  ;ActionScriptData example
  Define actionScriptObject.l, actionScriptInt.l, type.l
  result = FREGetContextActionScriptData(ctx, @actionScriptObject)
  *log\Debug(ResultDescription(result, "FREGetContextActionScriptData"))
  
  result = FREGetObjectType(actionScriptObject, @type)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectType"))
  *log\info("ContextActionScriptData: type=" + TypeDescription(type))
  
  result = FREGetObjectAsInt32(actionScriptObject, @actionScriptInt)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  *log\info("ContextActionScriptData: actionScriptInt=" + Str(actionScriptInt))

  
  ;function data example
  Define funcDataS.s
  funcDataS = PeekS(funcData, -1, #PB_Ascii)
  *log\info("FunctionData: " + funcDataS)
  
  *log\info("Method args size: " + Str(fromULong(argc)))

  Define resultObject.l, length.l, booleanArg.l, dwFlags.l, message.s, *string.Ascii
  
  result = FREGetObjectAsBool(*argv\object[0], @booleanArg)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsBool"))
  
  result = FREGetObjectAsInt32(*argv\object[1], @dwFlags)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsInt32"))
  
  result = FREGetObjectAsUTF8(*argv\object[2], @length, @*string)
  *log\Debug("result=" + ResultDescription(result, "FREGetObjectAsUTF8"))
  message = PeekS(*string, fromULong(length) + 1)
  
  *log\info("Argument: booleanArg=" + Str(fromULong(booleanArg)))
  *log\info("Argument: dwFlags=" + Str(dwFlags))
  *log\info("Argument: message=" + Utf8ToUnicode(message))
  
  ;native data example
  Define native.l, nativeData.s
  result = FREGetContextNativeData(ctx, @native)
  *log\Debug(ResultDescription(result, "FREGetContextNativeData"))
  nativeData = PeekS(native, -1, #PB_Ascii)
  *log\info("FREGetContextNativeData: " + nativeData)
  
  OnErrorCall(@ErrorHandler())
  ;Define hLib = LoadLibrary_("c:\windows\system32\MSVBVM60.DLL")
  ;If hLib
  ;   *log\info("loaded MSVBVM60: " + Str(hLib))
     If OpenLibrary(1, "c:\Dev\habrhabr\trunk\MathLib.dll")
       *log\info("called OpenLibrary(MathLib.dll)")

       Define pIID1.GUID, pIID2.GUID 
       
       Define pDummy.l, pDummyP.l
       ;  Set pIID = IID of IClassFactory 
       ;           = {00000001-0000-0000-C000-000000000046} 
       
       pIID1\Data1 = 1
       pIID1\Data4[0] = $C0
       pIID1\Data4[7] = $46
       
       pDummy = 0
       
       
       Define func.DllGetClassObject = GetFunction(1, "DllGetClassObject")
       *log\info("found DllGetClassObject: " + Str(func))
       Define inv.l = func(@pDummy, @pIID1, @pDummy)
       *log\info("called DllGetClassObject: " + Str(fromULong(inv)))
       
       Define arg.l = 100
       ;MessageRequester("", Str(CallFunction(1, "Decrement", arg)))
       ;ctx.l, funcData.l, argc.l, *argv.FREObjectArray
       
       Define *res.ResultData
       *res.ResultData = CallFunction(1, "TestCall", ctx, funcData, argc, *argv, @"test по-русски")
       MessageRequester("", *res\sResult)
       MessageRequester("", "Can unload now: " + Str(CallFunction(1, "DllCanUnloadNow")))
        
       
       CloseLibrary(1)
     Else
       *log\error("can not load c:\Dev\habrhabr\trunk\MathLib.dll")
     EndIf
  ;   FreeLibrary_(hLib)
  ;Else
  ;  *log\error("can not load MSVBVM60.DLL")
  ;EndIf

  
;   
;   Define *params.MessageParameters = AllocateMemory(SizeOf(MessageParameters))
;   *params\ctx = ctx
;   *params\title = "PureBasic"
;   *params\text = Utf8ToUnicode(message)
;   *params\dwFlags = dwFlags
;   CreateThread(@ModalMessage(), *params)
  
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
  f(0)\name = asGlobal("showDialog")
  ;function data example
  f(0)\functionData = asGlobal("showDialog")
  ;function pointer
  f(0)\function = @showDialog()

  *functions\l = @f()
  
  ;some additional data can be stored
  extData = #Null
  
  ;native data example
  result = FRESetContextNativeData(ctx, asGlobal("FRESetContextNativeData"))
  *log\Debug(ResultDescription(result, "FRESetContextNativeData"))
  
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
; CursorPosition = 108
; FirstLine = 81
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 174
; FirstLine = 132
; Folding = ---