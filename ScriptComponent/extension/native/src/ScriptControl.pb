;-TOP

;**
;* Kommentar    : ScriptControl 
;* Author       : Michael Kastner 
;* Datei        : ScriptControl.pb
;* Version      : 1.12 
;* Erstellt     : 10.07.2006 
;* Geandert     : 17.07.2010 

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

;- Object Structures
Structure Script
  *VTable
  ScriptControl.IScriptControl
EndStructure

;- Interface
Interface IScript
  Release()
  About()
  AddObject(name.s, *object)
  AddCode(Script.s)
  EvalVarType.l(StringVar.s)
  EvalVariant.l(StringVar.s, *Value.Variant)
  EvalDouble.d(StringVar.s)
  EvalFloat.f(StringVar.s)
  EvalQuad.q(StringVar.s)
  EvalLong.l(StringVar.s)
  EvalWord.w(StringVar.s)
  EvalByte.b(StringVar.s)
  EvalStr.s(StringVar.s)
  Reset()
  Run.l(Script.s)
  SetLanguage(Language.s)
  SetTimeOut(ms.l)
  GetTimeOut.l()
  SetSitehWnd(hWnd.l)
  GetSitehWnd.l()
  SetAllowUI(value.l)
  GetAllowUI.l()
  SetUseSafeSubset(value.l)
  GetUseSafeSubset.l()
  GetError.s()
EndInterface

; ***************************************************************************************


;** InitScriptControl

Procedure.l NewScript()
;- Create ScriptControl
  Define *oNew.Script
  *oNew = AllocateMemory (SizeOf(Script))
  InitializeStructure(*oNew, Script)
  
  *oNew\VTable  = ?VT_Script
  
  CoInitialize_(0)
  
  If CoCreateInstance_(?CLSID_ScriptControl, 0, 1, ?IID_IScriptControl, @*oNew\ScriptControl) = #S_OK
    *oNew\ScriptControl\Reset()
    *oNew\ScriptControl\put_Language("VBScript")
  EndIf
  
  ProcedureReturn *oNew
EndProcedure


;** Delete ScriptControl

Procedure SCtr__Release(*This.Script)
;- Destroy ScriptControl
  *This\ScriptControl\Release()
  CoUninitialize_()
  FreeMemory(*This)
EndProcedure

; ***************************************************************************************

;** SCtr__About
Procedure SCtr__About(*This.Script)
;- Show AboutBox for ScriptControl
  *This\ScriptControl\_AboutBox()
EndProcedure

;** SCtr__AddObject
Procedure SCtr__AddObject(*This.Script, name.s, *object)
;- Add an object to the global namespace of the scripting engine
  ProcedureReturn *This\ScriptControl\AddObject(name, *object, 0)
EndProcedure

;** SCtr__AddCode
Procedure SCtr__AddCode(*This.Script, Script.s)
;-  Add code to the global module
  ProcedureReturn *This\ScriptControl\AddCode(Script)
EndProcedure

;**SCtr__EvalVarType
;* Get variable type, returns LONG Variant Type
Procedure.l SCtr__EvalVarType(*This.Script, StringVar.s)
  Protected var.VARIANT
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
    ProcedureReturn var\vt
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;** SCtr__EvalVariant
;* Read variant variable
Procedure.l SCtr__EvalVariant(*This.Script, StringVar.s, *Value.Variant)
  Protected var.VARIANT, result.l
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalDate
;* Read Date variable, Unix Date (Long)
Procedure.l SCtr__EvalDate(*This.Script, StringVar.s)
  Protected var.VARIANT, result.l
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalDouble
;* Read double variable
Procedure.d SCtr__EvalDouble(*This.Script, StringVar.s)
  Protected var.VARIANT, result.d
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalFloat
;* Read float variable
Procedure.f SCtr__EvalFloat(*This.Script, StringVar.s)
  Protected var.VARIANT, result.f
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalQuad
;* Read quad variable
Procedure.q SCtr__EvalQuad(*This.Script, StringVar.s)
  Protected var.VARIANT, result.q
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalLong
;* Read loang variable
Procedure.l SCtr__EvalLong(*This.Script, StringVar.s)
  Protected var.VARIANT, result.l
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalWord
;* Read word variable
Procedure.w SCtr__EvalWord(*This.Script, StringVar.s)
  Protected var.VARIANT, result.w
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalByte
;* Read byte variable
Procedure.b SCtr__EvalByte(*This.Script, StringVar.s)
  Protected var.VARIANT, result.b
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__EvalStr
;* Read string variable
Procedure.s SCtr__EvalStr(*This.Script, StringVar.s)
  Protected var.VARIANT, result.s
  If *This\ScriptControl\Eval(StringVar, @var) = #S_OK
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

;** SCtr__Reset
Procedure SCtr__Reset(*This.Script)
;- Reset the scripting engine to a newly created state
  ProcedureReturn *This\ScriptControl\Reset()
EndProcedure

;** SCtr__Run
Procedure.l SCtr__Run(*This.Script, Script.s)
;- Call a procedure defined in the global module
  ProcedureReturn *This\ScriptControl\ExecuteStatement(Script)
EndProcedure

;** SCtr__SetLanguage
Procedure SCtr__SetLanguage(*This.Script, Language.s)
;- Language engine to use("VBScript" or "JScript", default is "VBSCript")
  ProcedureReturn *This\ScriptControl\put_Language(Language)
EndProcedure

;** SCtr__SetTimeOut
Procedure SCtr__SetTimeOut(*This.Script, ms.l)
;-  Length of time in milliseconds that a script can execute before being considered hung
  ProcedureReturn *This\ScriptControl\put_Timeout(ms)
EndProcedure

;** SCtr__GetTimeOut
Procedure.l SCtr__GetTimeOut(*This.Script)
;-  Length of time in milliseconds that a script can execute before being considered hung
  Protected timeout.l
  *This\ScriptControl\get_Timeout(@timeout)
  ProcedureReturn timeout
EndProcedure


;** SCtr__SetSitehWnd
Procedure SCtr__SetSitehWnd(*This.Script, hWnd.l)
;-  hWnd used as a parent for displaying UI
  ProcedureReturn *This\ScriptControl\put_SitehWnd(hWnd)
EndProcedure

;** SCtr__GetSitehWnd
Procedure.l SCtr__GetSitehWnd(*This.Script)
;-  hWnd used as a parent for displaying UI
  Protected hWnd.l
  *This\ScriptControl\get_SitehWnd(@hwnd)
  ProcedureReturn hWnd
EndProcedure


;** SCtr__SetAllowUI
Procedure SCtr__SetAllowUI(*This.Script, value.l)
;-  hWnd used as a parent for displaying UI
  ProcedureReturn *This\ScriptControl\put_AllowUI(value)
EndProcedure

;** SCtr__GetAllowUI
Procedure.l SCtr__GetAllowUI(*This.Script)
;-  hWnd used as a parent for displaying UI
  Protected value.l
  *This\ScriptControl\get_AllowUI(@value)
  ProcedureReturn value
EndProcedure

;** SCtr__SetUseSafeSubset
Procedure SCtr__SetUseSafeSubset(*This.Script, value.l)
;-  hWnd used as a parent for displaying UI
  ProcedureReturn *This\ScriptControl\put_UseSafeSubset(value)
EndProcedure

;** SCtr__GetUseSafeSubset
Procedure.l SCtr__GetUseSafeSubset(*This.Script)
;-  hWnd used as a parent for displaying UI
  Protected value.l
  *This\ScriptControl\get_UseSafeSubset(@value)
  ProcedureReturn value
EndProcedure

Procedure.s ErrorJSON(number.l, description.s, source.s, line.l, text.s)
  Define template.s = "{'line':{line},'source':'{source}','description':'{description}','text':'{text}','number':{number}}"
  template= ReplaceString(template, "'", #DOUBLEQUOTE$)
  
  template= ReplaceString(template, "{line}", Str(line))
  template= ReplaceString(template, "{description}", ReplaceString(description, #DOUBLEQUOTE$, "'"))
  template= ReplaceString(template, "{source}", ReplaceString(source, #DOUBLEQUOTE$, "'"))
  template= ReplaceString(template, "{text}", ReplaceString(text, #DOUBLEQUOTE$, "'"))
  template= ReplaceString(template, "{number}", Str(number))
 
  ProcedureReturn template
EndProcedure


;** SCtr__GetError
Procedure.s SCtr__GetError(*This.Script)
;- The last error reported by the scripting engine
  Protected ScriptError.IScriptError
  Protected Line.l, Description.l, DescriptionText.s, Result.s, number.l, text.l, textString.s, source.l, sourceString.s
  If *This\ScriptControl\get_Error(@ScriptError) = #S_OK
    ScriptError\get_Line(@Line)
    ScriptError\get_Number(@number)
    
    If ScriptError\get_Source(@source) = #S_OK
      If source
        sourceString = PeekS(source)
        ;sourceString = UnicodeToUtf8(sourceString)
      Else
        sourceString = "No Source"
      EndIf
    EndIf
    
    If ScriptError\get_Description(@Description) = #S_OK
      If Description
        DescriptionText = PeekS(Description)
        ;DescriptionText = UnicodeToUtf8(DescriptionText)
      Else
        DescriptionText = "No Error"
      EndIf
    EndIf
    
    If ScriptError\get_Text(@text) = #S_OK
      If text
        textString = PeekS(text)
        ;textString = UnicodeToUtf8(textString)
      Else
        textString = "No Text"
      EndIf
    EndIf
    
    ScriptError\Clear()
    ScriptError\Release()
    
    Result = ErrorJSON(number, DescriptionText, sourceString, Line, textString)
  Else
    Result = ErrorJSON(1, "SCtr__GetError failed", "", 0, "")
  EndIf
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

;-T_BSTR
Procedure helpSysAllocString(*Value)
  ProcedureReturn SysAllocString_(*Value)
EndProcedure
Prototype.l ProtoSysAllocString(Value.p-unicode)

Global T_BSTR.ProtoSysAllocString = @helpSysAllocString()

;- DATA SECTION
DataSection
  
    CLSID_ScriptControl:
    Data.l $0E59F1D5
    Data.w $1FBE,$11D0
    Data.b $8F,$F2,$00,$A0,$D1,$00,$38,$BC
  
    IID_IScriptControl:
    Data.l $0E59F1D3
    Data.w $1FBE,$11D0
    Data.b $8F,$F2,$00,$A0,$D1,$00,$38,$BC
   
    ; Own VT, function pointers
    VT_Script:
    Data.i @SCtr__Release()
    Data.i @SCtr__About()
    Data.i @SCtr__AddObject()
    Data.i @SCtr__AddCode()
    Data.i @SCtr__EvalVarType()
    Data.i @SCtr__EvalVariant()
    Data.i @SCtr__EvalDouble()
    Data.i @SCtr__EvalFloat()
    Data.i @SCtr__EvalQuad()
    Data.i @SCtr__EvalLong()
    Data.i @SCtr__EvalWord()
    Data.i @SCtr__EvalByte()
    Data.i @SCtr__EvalStr()
    Data.i @SCtr__Reset()
    Data.i @SCtr__Run()
    Data.i @SCtr__SetLanguage()
    Data.i @SCtr__SetTimeOut()
    Data.i @SCtr__GetTimeOut()
    Data.i @SCtr__SetSitehWnd()
    Data.i @SCtr__GetSitehWnd()
    Data.i @SCtr__SetAllowUI()
    Data.i @SCtr__GetAllowUI()
    Data.i @SCtr__SetUseSafeSubset()
    Data.i @SCtr__GetUseSafeSubset()
    Data.i @SCtr__GetError()
EndDataSection
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 547
; FirstLine = 528
; Folding = ------
; EnableXP