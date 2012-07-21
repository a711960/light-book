;-TOP

;**
;* Kommentar    : ScriptControl _
;* Author 1     : ts-soft _
;* Author 2     : mk-soft _
;* Author 3     : Michael Kastner _
;* Datei        : ScriptControl.pb _
;* Version      : 1.12 _
;* Erstellt     : 10.07.2006 _
;* Geandert     : 17.07.2010 _

EnableExplicit

;** i IScriptControl
Interface IScriptControl Extends IDispatch
;- Interface for ScriptControl
  get_Language(a)
  put_Language(strLanguage.p-bstr)
  get_State(a)
  put_State(a)
  put_SitehWnd(a)
  get_SitehWnd(a)
  get_Timeout(timeout)
  put_Timeout(timeout)
  get_AllowUI(a)
  put_AllowUI(a)
  get_UseSafeSubset(a)
  put_UseSafeSubset(a)
  get_Modules(a)
  get_Error(a)
  get_CodeObject(a)
  get_Procedures(a)
  _AboutBox()
  AddObject(name.p-bstr,*object,addmembers)
  Reset()
  AddCode(source.p-bstr)
  Eval(a.p-bstr,*b.VARIANT)
  ExecuteStatement(a.p-bstr)
  Run(strCommand.p-bstr, intWindowStyle.l, bWaitOnReturn.l)
EndInterface

Interface IScriptError ; Provides access to scripting error information
;- Interface for scripting error information
  QueryInterface(riid.l,ppvObj.l)
  AddRef()
  Release()
  GetTypeInfoCount(pctinfo.l)
  GetTypeInfo(itinfo.l,lcid.l,pptinfo.l)
  GetIDsOfNames(riid.l,rgszNames.l,cNames.l,lcid.l,rgdispid.l)
  Invoke(dispidMember.l,riid.l,lcid.l,wFlags.l,pdispparams.l,pvarResult.l,pexcepinfo.l,puArgErr.l)
  get_Number(dispidMember.l)
  get_Source(dispidMember.l)
  get_Description(dispidMember.l)
  get_HelpFile(dispidMember.l)
  get_HelpContext(dispidMember.l)
  get_Text(dispidMember.l)
  get_Line(dispidMember.l)
  get_Column(dispidMember.l)
  Clear()
EndInterface

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

; ***************************************************************************************

;** InitScriptControl

Procedure InitScriptControl()
;- Create ScriptControl
  ;** g ScriptControl
  ;* Interfacevariable
  Global ScriptControl.IScriptControl
 
  CoInitialize_(0)
  If CoCreateInstance_(?CLSID_ScriptControl, 0, 1, ?IID_IScriptControl, @ScriptControl) = #S_OK
    ScriptControl\Reset()
    ScriptControl\put_Language("VBScript")
  EndIf
  DataSection
  CLSID_ScriptControl:
  Data.l $0E59F1D5
  Data.w $1FBE,$11D0
  Data.b $8F,$F2,$00,$A0,$D1,$00,$38,$BC

  IID_IScriptControl:
  Data.l $0E59F1D3
  Data.w $1FBE,$11D0
  Data.b $8F,$F2,$00,$A0,$D1,$00,$38,$BC
  EndDataSection
EndProcedure


;** Delete ScriptControl

Procedure DeleteScriptControl()
;- Destroy ScriptControl
  ScriptControl\Release()
  CoUninitialize_()
EndProcedure

; ***************************************************************************************

;** SCtr_About
Procedure SCtr_About()
;- Show AboutBox for ScriptControl
  ScriptControl\_AboutBox()
EndProcedure

;** SCtr_AddObject
Procedure SCtr_AddObject(name.s, *object)
;- Add an object to the global namespace of the scripting engine
  ProcedureReturn ScriptControl\AddObject(name, *object, 0)
EndProcedure

;** SCtr_AddCode
Procedure SCtr_AddCode(Script.s)
;-  Add code to the global module
  ProcedureReturn ScriptControl\AddCode(Script)
EndProcedure

;**SCtr_EvalVarType
;* Get variable type, returns LONG Variant Type
Procedure.l SCtr_EvalVarType(StringVar.s)
  Protected var.VARIANT
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    ProcedureReturn var\vt
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalVariant
;* Read variant variable
Procedure.l SCtr_EvalVariant(StringVar.s, *Value.Variant)
  Protected var.VARIANT, result.l
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    VariantClear_(*Value)
    If VariantCopy_(*Value, var) = #S_OK
      result = #True
    Else
      result = #False
    EndIf
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

;** SCtr_EvalDate
;* Read Date variable, Unix Date (Long)
Procedure.l SCtr_EvalDate(StringVar.s)
  Protected var.VARIANT, result.l
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_DATE
        result = (var\dblVal) * 86400 - 2209161600
      Default
        result = 0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalDouble
;* Read double variable
Procedure.d SCtr_EvalDouble(StringVar.s)
  Protected var.VARIANT, result.d
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_BOOL
        result =  var\boolVal
      Case #VT_I1, #VT_UI1
        result = var\bVal
      Case #VT_I2, #VT_UI2
        result = var\iVal
      Case #VT_I4, #VT_UI4
        result = var\lVal
      Case #VT_I8, #VT_UI8
        result = var\llVal
      Case #VT_R4
        result = var\fltVal
      Case #VT_R8, #VT_DATE
        result = var\dblVal
      Case #VT_BSTR
        result = ValD(PeekS(var\bstrVal, #PB_Any, #PB_Unicode))
      Default
        result = 0.0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0.0
  EndIf
EndProcedure

;** SCtr_EvalFloat
;* Read float variable
Procedure.f SCtr_EvalFloat(StringVar.s)
  Protected var.VARIANT, result.f
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_BOOL
        result =  var\boolVal
      Case #VT_I1, #VT_UI1
        result = var\bVal
      Case #VT_I2, #VT_UI2
        result = var\iVal
      Case #VT_I4, #VT_UI4
        result = var\lVal
      Case #VT_I8, #VT_UI8
        result = var\llVal
      Case #VT_R4
        result = var\fltVal
      Case #VT_R8, #VT_DATE
        result = var\dblVal
      Case #VT_BSTR
        result = ValF(PeekS(var\bstrVal, #PB_Any, #PB_Unicode))
      Default
        result = 0.0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0.0
  EndIf
EndProcedure

;** SCtr_EvalQuad
;* Read quad variable
Procedure.q SCtr_EvalQuad(StringVar.s)
  Protected var.VARIANT, result.q
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_BOOL
        result =  var\boolVal
      Case #VT_I1, #VT_UI1
        result = var\bVal
      Case #VT_I2, #VT_UI2
        result = var\iVal
      Case #VT_I4, #VT_UI4
        result = var\lVal
      Case #VT_I8, #VT_UI8
        result = var\llVal
      Case #VT_R4
        result = var\fltVal
      Case #VT_R8, #VT_DATE
        result = var\dblVal
      Case #VT_BSTR
        result = Val(PeekS(var\bstrVal, #PB_Any, #PB_Unicode))
      Default
        result = 0.0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalLong
;* Read loang variable
Procedure.l SCtr_EvalLong(StringVar.s)
  Protected var.VARIANT, result.l
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_BOOL
        result =  var\boolVal
      Case #VT_I1, #VT_UI1
        result = var\bVal
      Case #VT_I2, #VT_UI2
        result = var\iVal
      Case #VT_I4, #VT_UI4
        result = var\lVal
      Case #VT_I8, #VT_UI8
        result = var\llVal
      Case #VT_R4
        result = var\fltVal
      Case #VT_R8, #VT_DATE
        result = var\dblVal
      Case #VT_BSTR
        result = Val(PeekS(var\bstrVal, #PB_Any, #PB_Unicode))
      Default
        result = 0.0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalWord
;* Read word variable
Procedure.w SCtr_EvalWord(StringVar.s)
  Protected var.VARIANT, result.w
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_BOOL
        result =  var\boolVal
      Case #VT_I1, #VT_UI1
        result = var\bVal
      Case #VT_I2, #VT_UI2
        result = var\iVal
      Case #VT_I4, #VT_UI4
        result = var\lVal
      Case #VT_I8, #VT_UI8
        result = var\llVal
      Case #VT_R4
        result = var\fltVal
      Case #VT_R8, #VT_DATE
        result = var\dblVal
      Case #VT_BSTR
        result = Val(PeekS(var\bstrVal, #PB_Any, #PB_Unicode))
      Default
        result = 0.0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalByte
;* Read byte variable
Procedure.b SCtr_EvalByte(StringVar.s)
  Protected var.VARIANT, result.b
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    Select var\vt
      Case #VT_BOOL
        result =  var\boolVal
      Case #VT_I1, #VT_UI1
        result = var\bVal
      Case #VT_I2, #VT_UI2
        result = var\iVal
      Case #VT_I4, #VT_UI4
        result = var\lVal
      Case #VT_I8, #VT_UI8
        result = var\llVal
      Case #VT_R4
        result = var\fltVal
      Case #VT_R8, #VT_DATE
        result = var\dblVal
      Case #VT_BSTR
        result = Val(PeekS(var\bstrVal, #PB_Any, #PB_Unicode))
      Default
        result = 0.0
    EndSelect
    VariantClear_(var)
    ProcedureReturn result
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalStr
;* Read string variable
Procedure.s SCtr_EvalStr(StringVar.s)
  Protected var.VARIANT, result.s
  If ScriptControl\Eval(StringVar, @var) = #S_OK
   Select var\vt
      Case #VT_BOOL
        If var\boolVal = #VARIANT_TRUE
          result = "TRUE"
        Else
          result = "FALSE"
        EndIf
      Case #VT_BSTR
        result = PeekS(var\bstrVal, #PB_Any, #PB_Unicode)
      Case #VT_I1, #VT_UI1
        result = Str(var\bVal)
      Case #VT_I2, #VT_UI2
        result = Str(var\iVal)
      Case #VT_I4, #VT_UI4
        result = Str(var\lVal)
      Case #VT_I8, #VT_UI8
        result = Str(var\llVal)
      Case #VT_R4
        result = StrF(var\fltVal)
      Case #VT_R8
        result = StrD(var\dblVal)
      Default
        result = ""
    EndSelect
    VariantClear_(var)
  Else
    result = ""
  EndIf
  ProcedureReturn result
EndProcedure

;** SCtr_Reset
Procedure SCtr_Reset()
;- Reset the scripting engine to a newly created state
  ProcedureReturn ScriptControl\Reset()
EndProcedure

;** SCtr_Run
Procedure SCtr_Run(Script.s)
;- Call a procedure defined in the global module
  ProcedureReturn ScriptControl\ExecuteStatement(Script)
EndProcedure

;** SCtr_SetLanguage
Procedure SCtr_SetLanguage(Language.s)
;- Language engine to use("VBScript" or "JScript", default is "VBSCript")
  ProcedureReturn ScriptControl\put_Language(Language)
EndProcedure

;** SCtr_SetTimeOut
Procedure SCtr_SetTimeOut(ms.l)
;-  Length of time in milliseconds that a script can execute before being considered hung
  ProcedureReturn ScriptControl\put_Timeout(ms)
EndProcedure

;** SCtr_GetTimeOut
Procedure.l SCtr_GetTimeOut()
;-  Length of time in milliseconds that a script can execute before being considered hung
  Protected timeout.l
  ScriptControl\get_Timeout(@timeout)
  ProcedureReturn timeout
EndProcedure


;** SCtr_SetSitehWnd
Procedure SCtr_SetSitehWnd(hWnd.l)
;-  hWnd used as a parent for displaying UI
  ProcedureReturn ScriptControl\put_SitehWnd(hWnd)
EndProcedure

;** SCtr_GetSitehWnd
Procedure.l SCtr_GetSitehWnd()
;-  hWnd used as a parent for displaying UI
  Protected hWnd.l
  ScriptControl\get_SitehWnd(@hwnd)
  ProcedureReturn hWnd
EndProcedure


;** SCtr_SetAllowUI
Procedure SCtr_SetAllowUI(value.l)
;-  hWnd used as a parent for displaying UI
  ProcedureReturn ScriptControl\put_AllowUI(value)
EndProcedure

;** SCtr_GetAllowUI
Procedure.l SCtr_GetAllowUI()
;-  hWnd used as a parent for displaying UI
  Protected value.l
  ScriptControl\get_AllowUI(@value)
  ProcedureReturn value
EndProcedure

;** SCtr_SetUseSafeSubset
Procedure SCtr_SetUseSafeSubset(value.l)
;-  hWnd used as a parent for displaying UI
  ProcedureReturn ScriptControl\put_UseSafeSubset(value)
EndProcedure

;** SCtr_GetUseSafeSubset
Procedure.l SCtr_GetUseSafeSubset()
;-  hWnd used as a parent for displaying UI
  Protected value.l
  ScriptControl\get_UseSafeSubset(@value)
  ProcedureReturn value
EndProcedure

;** SCtr_GetError
Procedure.s SCtr_GetError()
;- The last error reported by the scripting engine
  Protected ScriptError.IScriptError
  Protected Line, Description, DescriptionText.s, Result.s
  If ScriptControl\get_Error(@ScriptError) = #S_OK
    ScriptError\get_Line(@Line)
    If ScriptError\get_Description(@Description) = #S_OK
      If Description
        DescriptionText = PeekS(Description)
      Else
        DescriptionText = "No Error"
      EndIf
    EndIf
    ScriptError\Clear()
    ScriptError\Release()
  Else
    Result = "Fehler: SCtr_GetError"
  EndIf
  Result = "Line " + Str(Line) + ": " + DescriptionText
  ProcedureReturn Result
EndProcedure


Procedure.s VT_STR(*Var.Variant)
;- Helper Variant String 
  Protected hr.l, result.s, VarDest.Variant
  
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

Procedure CheckVT(*var.VARIANT, Type)
;- Helper Check Variant Type
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
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 12
; Folding = -----
; EnableXP