EnableExplicit

;- Object Structures
Structure udtObject
  *VTable
  cntRef.l
  *oOwn.IUnknown
  *oPar.IUnknown
  *oApp.IUnknown
EndStructure

Structure udtArgs
  ID.VARIANT[0]
EndStructure
 

Procedure NewObject(*VT_Application)
  Define *oNew.udtObject
 
  ;Create new Object
  *oNew         = AllocateMemory (SizeOf(udtObject))
  *oNew\VTable  = *VT_Application
  *oNew\oOwn    = *oNew
  *oNew\oPar    = *oNew
  *oNew\oApp    = *oNew
  *oNew\oOwn\AddRef()
  ProcedureReturn *oNew
EndProcedure


;- Method DispIds

;Smarttags Method id
#Smarttags  = 101
 
;- Method declarations

Declare Object_GetSmarttags(*This, *varname.string, *value.VARIANT)
Declare Object_PutSmarttags(*This, *varname.string, *value.VARIANT)
 
;- Object Variables

;Map with Variant values
Global NewMap Tags.VARIANT()
 
;- CLASS Interfaces

;Standard Interface
Procedure.l Object_QueryInterface(*This.udtObject, *iid.IID, *Object.Integer)
  ;Standardzuweisungen auf eigenes Objekt
  If CompareMemory(*iid, ?IID_IUnknown, 16) Or CompareMemory(*iid, ?IID_IDispatch, 16)
    *Object\i = *This : *This\oOwn\AddRef()
    ProcedureReturn #S_OK
  EndIf
  ProcedureReturn #E_NOINTERFACE
EndProcedure
  
;Standard Interface
Procedure.l Object_AddRef(*This.udtObject)
  *This\cntRef + 1
  ProcedureReturn *This\cntRef
EndProcedure
  
;Standard Interface
Procedure.l Object_Release(*This.udtObject)
  ;If reference count is not 0, decrement counter
  If *This\cntRef > 1
    *This\cntRef - 1
    ProcedureReturn *This\cntRef
  EndIf
  ;Release object
  FreeMemory(*This)
  ProcedureReturn 0
EndProcedure
  
;Standard Interface
Procedure.l Object_GetTypeInfoCount(*This.udtObject, *CntTypeInfo.Long)
  *CntTypeInfo\l = 0
  ProcedureReturn #S_OK
EndProcedure

;Standard Interface
Procedure.l Object_GetTypeInfo(*This.udtObject, TypeInfo.l, LocalId.l, *ppTypeInfo.Integer)
  ProcedureReturn #S_OK
EndProcedure
  
;Standard Interface, add method names/ids here
Procedure.l Object_GetIDsOfNames(*This.udtObject, *iid.IID, *Name.String, cntNames.l, lcid.l, *DispId.Long)
  Protected Name.s
  Name = LCase(*Name\s)
  ; Method names
  Select name
    Case "smarttags" 
      *DispId\l = #Smarttags
    Default
      ProcedureReturn #DISP_E_MEMBERNOTFOUND
  EndSelect
 
  ProcedureReturn #S_OK
EndProcedure
  
;Standard Interface, add method implementations here
Procedure.l Object_Invoke(*This.udtObject, DispId.l, *iid.IID, lcid.l, Flags.w, *DispParams.DISPPARAMS, *vResult.VARIANT, *ExcepInfo.EXCEPINFO, *ArgErr.Integer)
  Protected *vArg.udtArgs, r1
 
  *vArg = *DispParams\rgvarg
 
  Select DispId
    ; Check PropertyGet and PropertyPut via flags
     Case #Smarttags
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
       
      ; Function is not getter ot setter
      Else
        ProcedureReturn #DISP_E_BADPARAMCOUNT
       
      EndIf
     
    Default
      ProcedureReturn #DISP_E_MEMBERNOTFOUND
  EndSelect
EndProcedure
;End Standard Interfaces
 

;Begin Implementation 
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
;End Implementation
 

;- DATA SECTION
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
   
    ; Own VT, function pointers
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
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 186
; FirstLine = 151
; Folding = --
; EnableXP