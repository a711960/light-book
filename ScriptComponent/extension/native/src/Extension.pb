EnableExplicit

;#LOG_FILE = "C:\pureair.log"

XIncludeFile "Unsigned.pb"
XIncludeFile "Unicode.pb"
XIncludeFile "Logger.pb"
XIncludeFile "FlashRuntimeExtensions.pbi"
XIncludeFile "ScriptControl.pbi"

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


;- Strukturen ***************************************************************************

  Structure udtObject
    *VTable
    cntRef.l
    *oOwn.IUnknown
    *oPar.IUnknown
    *oApp.IUnknown
  EndStructure

  Structure EXCEPINFO
    wCode.w
    wReserved.w
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x64 : padding1.b[4] : CompilerEndIf
    bstrSource.s
    bstrDescription.s
    bstrHelpFile.s
    dwHelpContext.l
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x64 : padding2.b[4] : CompilerEndIf
    *pvReserved
    *pfnDeferredFillIn
    sCode.l
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x64 : padding3.b[4] : CompilerEndIf
  EndStructure
 
  Structure udtArgs
    ID.VARIANT[0]
  EndStructure
 
;- Helper Variant String ****************************************************************

Procedure.s VT_STR(*Var.Variant)

  Protected hr.l, result.s, VarDest.Variant
 
  ;vhLastError = 0
 
  If *Var
    hr = VariantChangeType_(VarDest, *Var, 0, #VT_BSTR)
    If hr = #S_OK
      result = PeekS(VarDest\bstrVal, #PB_Any, #PB_Unicode)
      VariantClear_(VarDest)
      ProcedureReturn result
    Else
      ProcedureReturn ""
    EndIf
   
  EndIf
EndProcedure

;- Helper Check Variant Type ************************************************************

Procedure CheckVT(*var.VARIANT, Type)
 
  Protected *va.VARIANT
 
  If *var\vt & #VT_VARIANT = #VT_VARIANT
    *va = *var\pvarVal
  Else
    *va = *var
  EndIf
  If *va\vt & #VT_TYPEMASK <> Type
    ProcedureReturn #DISP_E_BADVARTYPE
  Else
    ProcedureReturn #S_OK
  EndIf
 
EndProcedure

;- Helper New Object ********************************************************************

Procedure NewObject(*VT_Application)
 
  Define *oNew.udtObject
 
  ;Eine neues Applikationsobjekt erstellen
  *oNew         = AllocateMemory (SizeOf(udtObject))
  *oNew\VTable  = *VT_Application
  *oNew\oOwn    = *oNew
  *oNew\oPar    = *oNew
  *oNew\oApp    = *oNew
  *oNew\oOwn\AddRef()
  ProcedureReturn *oNew
 
EndProcedure

; ***************************************************************************************

;- Konstanten ***************************************************************************

; DispIds

  #Smarttags  = 101
 
;- Deklarationen ************************************************************************

  Declare Object_GetSmarttags(*This, *varname.string, *value.VARIANT)
  Declare Object_PutSmarttags(*This, *varname.string, *value.VARIANT)
 
;- Globale Variablen, Listen
 
  Global NewMap Tags.VARIANT()
 
;- CLASS OBJECT *************************************************************************

  ; Begin Standard Interfaces

  Procedure.l Object_QueryInterface(*This.udtObject, *iid.IID, *Object.Integer)
   
    ;Standardzuweisungen auf eigenes Objekt
    If CompareMemory(*iid, ?IID_IUnknown, 16) Or CompareMemory(*iid, ?IID_IDispatch, 16)
      *Object\i = *This : *This\oOwn\AddRef()
      ProcedureReturn #S_OK
    EndIf

    ProcedureReturn #E_NOINTERFACE

  EndProcedure
 
  Procedure.l Object_AddRef(*This.udtObject)

    *This\cntRef + 1
    ProcedureReturn *This\cntRef

  EndProcedure
 
  Procedure.l Object_Release(*This.udtObject)

    ;Wenn Referenzzahler nicht auf 0 kommt
    If *This\cntRef > 1
      *This\cntRef - 1
      ProcedureReturn *This\cntRef
    EndIf

    ;Eigenes Objekt auflosen
    FreeMemory(*This)
    ProcedureReturn 0

  EndProcedure
 
  Procedure.l Object_GetTypeInfoCount(*This.udtObject, *CntTypeInfo.Long)
   
    *CntTypeInfo\l = 0
    ProcedureReturn #S_OK

  EndProcedure
 
  Procedure.l Object_GetTypeInfo(*This.udtObject, TypeInfo.l, LocalId.l, *ppTypeInfo.Integer)
   
    ProcedureReturn #S_OK

  EndProcedure
 
  Procedure.l Object_GetIDsOfNames(*This.udtObject, *iid.IID, *Name.String, cntNames.l, lcid.l, *DispId.Long)
   
    Protected Name.s
   
    Name = LCase(*Name\s)
    ; Hier die Funktionsnamen auf DispId auflosen
    Select name
      Case "smarttags" 
        *DispId\l = #Smarttags
       
      Default
        ProcedureReturn #DISP_E_MEMBERNOTFOUND
       
    EndSelect
   
    ProcedureReturn #S_OK
   
  EndProcedure
 
  Procedure.l Object_Invoke(*This.udtObject, DispId.l, *iid.IID, lcid.l, Flags.w, *DispParams.DISPPARAMS, *vResult.VARIANT, *ExcepInfo.EXCEPINFO, *ArgErr.Integer)
   
    Protected *vArg.udtArgs, r1
   
    *vArg = *DispParams\rgvarg
   
    Select DispId
      ; Hier werden die Funktionen aufgerufen
      ; Mit den Flags kann man den Type PropertyGet oder PropertyPut unterscheiden 
       Case #Smarttags
        ; Funktion fur Get aufrufen
        If Flags & #DISPATCH_PROPERTYGET = #DISPATCH_PROPERTYGET
          ; Hier werden die Anzahl der Parameter uberpruft
          If *Dispparams\cArgs <> 1
            ProcedureReturn #DISP_E_BADPARAMCOUNT
          EndIf
          ; Hier werden die Typen der Parameter uberpruft
          If CheckVT(*vArg\ID[0], #VT_BSTR)
            ProcedureReturn #DISP_E_BADVARTYPE
          EndIf
          Object_GetSmarttags(*This, *vArg\ID[0], *vResult)
          ProcedureReturn #S_OK
         
        ; Funktion fur Put aufrufen
        ElseIf Flags & #DISPATCH_PROPERTYPUT = #DISPATCH_PROPERTYPUT
          ; Hier werden die Anzahl der Parameter uberpruft
          If *Dispparams\cArgs <> 2
            ProcedureReturn #DISP_E_BADPARAMCOUNT
          EndIf
          ; Hier werden die Typen der Parameter uberpruft
          If CheckVT(*vArg\ID[1], #VT_BSTR)
            ProcedureReturn #DISP_E_BADVARTYPE
          EndIf
          Object_PutSmarttags(*This, *vArg\ID[1], *vArg\ID[0])
          ProcedureReturn #S_OK
         
        ; Funktion wurde ohne Get oder Put aufgerufen
        Else
          ProcedureReturn #DISP_E_BADPARAMCOUNT
         
        EndIf
       
      Default
        ProcedureReturn #DISP_E_MEMBERNOTFOUND
         
    EndSelect

  EndProcedure
 
  ; End Standard Interfaces
 
  ; Begin Eigene Interfaces
 
  Procedure Object_GetSmarttags(*this, *varname.VARIANT, *value.VARIANT)
   
    Protected *p, name.s
   
    name = VT_STR(*varname)
   
    If FindMapElement(Tags(), name)
      *p = @Tags()
      VariantCopy_(*value, *p)
    Else
      VariantClear_(*value)
    EndIf
   
  EndProcedure
 
  Procedure Object_PutSmarttags(*this, *varname.VARIANT, *value.VARIANT)
   
    Protected *p, name.s
   
    name = VT_STR(*varname)
    If AddMapElement(Tags(), name)
      *p = @Tags()
      VariantCopy_(*p, *value)
    EndIf
   
  EndProcedure
 
  ; End Eigene Interfaces
 
;- DATA SECTION *************************************************************************

  DataSection

    ; Standard IID
    IID_IUnknown: ; {00000000-0000-0000-C000-000000000046}
    Data.l $00000000
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46

    IID_IDispatch: ; {00020400-0000-0000-C000-000000000046}
    Data.l $00020400
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
   
    ; Eigene VT
    VT_Smarttags:
    Data.i @Object_QueryInterface()
    Data.i @Object_AddRef()
    Data.i @Object_Release()
    Data.i @Object_GetTypeInfoCount()
    Data.i @Object_GetTypeInfo()
    Data.i @Object_GetIDsOfNames()
    Data.i @Object_Invoke()
    Data.i @Object_GetSmarttags()
    Data.i @Object_PutSmarttags()
   
   
  EndDataSection
 
; ***************************************************************************************

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
  
  InitScriptControl()

  Tags("Zahl")\vt = #VT_R8
  Tags()\dblVal = 100.95

  Define vbs.s
  ; VB-Script
  vbs = "Dim name, value" + #CRLF$
  vbs + "name = 'VB-Zahl'" + #CRLF$
  vbs + "My.Smarttags(name) = 20" + #CRLF$
  vbs + "My.Smarttags('Text') = 'Hallo Welt'" + #CRLF$
  vbs + "value = My.Smarttags('Zahl')" + #CRLF$
  vbs + "MsgBox 'Value = ' & value"

  vbs = ReplaceString(vbs, "'", #DOUBLEQUOTE$)

  SCtr_SetLanguage("VBScript")
  SCtr_SetTimeOut(20000)
  SCtr_AddObject("My", NewObject(?VT_Smarttags))
  Define r1.l = SCtr_AddCode(vbs)
  If r1 <> #S_OK
    *log\error(SCtr_GetError())
  EndIf

  Define result.d = SCtr_EvalDouble("value")
  *log\info("value = " + StrD(result))

  ForEach tags()
    *log\info("Map(" + MapKey(Tags()) + "): " + VT_STR(Tags()))
  Next

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
; CursorPosition = 479
; FirstLine = 440
; Folding = -----