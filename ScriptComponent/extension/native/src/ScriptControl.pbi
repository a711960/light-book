;-TOP
;**
;* Kommentar    : ScriptControl _
;* Author 1     : ts-soft _
;* Author 2     : mk-soft _
; Author 3      :
;* Datei        : ScriptControl.pb _
;* Version      : 1.12 _
;* Erstellt     : 10.07.2006 _
;* Geandert     : 17.07.2010 _

;** i IScriptControl
;* Interface fur ScriptControl
Interface IScriptControl Extends IDispatch
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

; ***************************************************************************************

;** InitScriptControl

Procedure InitScriptControl()
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
  ScriptControl\Release()
  CoUninitialize_()
EndProcedure

; ***************************************************************************************

;** SCtr_About
;* erzeugt eine AboutBox vom ScriptControl
Procedure SCtr_About()
  ScriptControl\_AboutBox()
EndProcedure

;** SCtr_AddObject
;* Object hinzufugen
Procedure SCtr_AddObject(name.s, *object)
  ProcedureReturn ScriptControl\AddObject(name, *object, 0)
EndProcedure

;** SCtr_AddCode
;* Code hinzufugen
Procedure SCtr_AddCode(Script.s)
  ProcedureReturn ScriptControl\AddCode(Script)
EndProcedure

;**SCtr_EvalVarType
;* Einen VariablenType lesen, ist LONG Variant Type
Procedure.l SCtr_EvalVarType(StringVar.s)
  Protected var.VARIANT
  If ScriptControl\Eval(StringVar, @var) = #S_OK
    ProcedureReturn var\vt
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr_EvalVariant
;* Einen Variablenwert lesen, ist Variant
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
;* Einen Variablenwert lesen, ist Unix Datum (Long)
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
;* Einen Variablenwert lesen, ist DOUBLE
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
;* Einen Variablenwert lesen, ist FLOAT
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
;* Einen Variablenwert lesen, ist Quad
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
;* Einen Variablenwert lesen, ist LONG
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
;* Einen Variablenwert lesen, ist WORD
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
;* Einen Variablenwert lesen, ist BYTE
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
;* Einen Variablenwert lesen, ist String
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
;* Setzt das Control zuruck
Procedure SCtr_Reset()
  ProcedureReturn ScriptControl\Reset()
EndProcedure

;** SCtr_Run
;* Funktion im Code aufrufen, der mit AddCode hinzugefugt wurde!
Procedure SCtr_Run(Script.s)
  ProcedureReturn ScriptControl\ExecuteStatement(Script)
EndProcedure

;** SCtr_SetLanguage
;* Die Sprache einstellen (zB "VBScript" oder "JScript", default ist "VBSCript"
Procedure SCtr_SetLanguage(Language.s)
  ProcedureReturn ScriptControl\put_Language(Language)
EndProcedure

;** SCtr_SetTimeOut
;* Timeoutwert setzen
Procedure SCtr_SetTimeOut(ms.l)
  ProcedureReturn ScriptControl\put_Timeout(ms)
EndProcedure

;** SCtr_GetTimeOut
;* Ermitteln welchen Wert TimeOut hat (Default 10000)
Procedure SCtr_GetTimeOut()
  Protected timeout.l
  ScriptControl\get_Timeout(@timeout)
  ProcedureReturn timeout
EndProcedure

;** SCtr_GetError
;* Ermitteln den Fehler (Line + Description)
Procedure.s SCtr_GetError()
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
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 441
; Folding = ----
; EnableXP