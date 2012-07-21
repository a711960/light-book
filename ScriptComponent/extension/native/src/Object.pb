EnableExplicit

;- Object Structures
Structure objObject
  *VTable
  cntRef.l
  *oOwn.IUnknown
  *oPar.IUnknown
  *oApp.IUnknown
  Map Values.VARIANT()
EndStructure

Structure objArgs
  ID.VARIANT[0]
EndStructure
 

Procedure.l NewObject(*VT_Application)
  Define *oNew.objObject
 
  ;Create new Object
  *oNew         = AllocateMemory (SizeOf(objObject))
  ;structures with arrays lists and maps must be initialized
  InitializeStructure(*oNew, objObject)
  *oNew\VTable  = *VT_Application
  *oNew\oOwn    = *oNew
  *oNew\oPar    = *oNew
  *oNew\oApp    = *oNew
  *oNew\oOwn\AddRef()
  ProcedureReturn *oNew
EndProcedure


;- Method DispIds

;Smarttags Method id
#Items  = 101
 
;- Method declarations

Declare Object_GetValue(*This, *varname.string, *value.VARIANT)
Declare Object_SetValue(*This, *varname.string, *value.VARIANT)
 
;- Object Variables



;- CLASS Interfaces

;Standard Interface
Procedure.l Object_QueryInterface(*This.objObject, *iid.IID, *Object.Integer)
  ;Standardzuweisungen auf eigenes Objekt
  If CompareMemory(*iid, ?IID_IUnknown, 16) Or CompareMemory(*iid, ?IID_IDispatch, 16)
    *Object\i = *This : *This\oOwn\AddRef()
    ProcedureReturn #S_OK
  EndIf
  ProcedureReturn #E_NOINTERFACE
EndProcedure
  
;Standard Interface
Procedure.l Object_AddRef(*This.objObject)
  *This\cntRef + 1
  ProcedureReturn *This\cntRef
EndProcedure
  
;Standard Interface
Procedure.l Object_Release(*This.objObject)
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
Procedure.l Object_GetTypeInfoCount(*This.objObject, *CntTypeInfo.Long)
  *CntTypeInfo\l = 0
  ProcedureReturn #S_OK
EndProcedure

;Standard Interface
Procedure.l Object_GetTypeInfo(*This.objObject, TypeInfo.l, LocalId.l, *ppTypeInfo.Integer)
  ProcedureReturn #S_OK
EndProcedure
  
;Standard Interface, add method names/ids here
Procedure.l Object_GetIDsOfNames(*This.objObject, *iid.IID, *Name.String, cntNames.l, lcid.l, *DispId.Long)
  Protected Name.s
  Name = LCase(*Name\s)
  ; Method names
  Select name
    Case "items" 
      *DispId\l = #Items
    Default
      ProcedureReturn #DISP_E_MEMBERNOTFOUND
  EndSelect
 
  ProcedureReturn #S_OK
EndProcedure
  
;Standard Interface, add method implementations here
Procedure.l Object_Invoke(*This.objObject, DispId.l, *iid.IID, lcid.l, Flags.w, *DispParams.DISPPARAMS, *vResult.VARIANT, *ExcepInfo.EXCEPINFO, *ArgErr.Integer)
  Protected *vArg.objArgs, r1
 
  Select DispId
    ; Check PropertyGet and PropertyPut via flags
    Case #Items
       *vArg = *DispParams\rgvarg 
       If Flags & #DISPATCH_PROPERTYGET = #DISPATCH_PROPERTYGET
        ; Expected exectly 1 argument
        If *Dispparams\cArgs <> 1
          ProcedureReturn #DISP_E_BADPARAMCOUNT
        EndIf
        ; Expected string argument
        If CheckVT(*vArg\ID[0], #VT_BSTR)
          ProcedureReturn #DISP_E_BADVARTYPE
        EndIf
        Object_GetValue(*This, *vArg\ID[0], *vResult)
        ProcedureReturn #S_OK
       
      ElseIf Flags & #DISPATCH_PROPERTYPUT = #DISPATCH_PROPERTYPUT
        ; Expected exectly 2 argument
        If *Dispparams\cArgs <> 2
          ProcedureReturn #DISP_E_BADPARAMCOUNT
        EndIf
        ; Expected string value
        If CheckVT(*vArg\ID[1], #VT_BSTR)
          ProcedureReturn #DISP_E_BADVARTYPE
        EndIf
        Object_SetValue(*This, *vArg\ID[1], *vArg\ID[0])
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
Procedure Object_GetValue(*This.objObject, *varname.VARIANT, *value.VARIANT)
  Protected *p, name.s
 
  name = VT_STR(*varname)
   
  If FindMapElement(*This\Values(), name)
    *p = @*This\Values()
    VariantCopy_(*value, *p)
  Else
    VariantClear_(*value)
  EndIf
EndProcedure
 
Procedure Object_SetValue(*This.objObject, *varname.VARIANT, *value.VARIANT)
  Protected *p, name.s
 
  name = VT_STR(*varname)
  If AddMapElement(*This\Values(), name)
    *p = @*This\Values()
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
    VT_Object:
    Data.i @Object_QueryInterface()
    Data.i @Object_AddRef()
    Data.i @Object_Release()
    Data.i @Object_GetTypeInfoCount()
    Data.i @Object_GetTypeInfo()
    Data.i @Object_GetIDsOfNames()
    Data.i @Object_Invoke()
    Data.i @Object_GetValue()
    Data.i @Object_SetValue()
EndDataSection
  
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 106
; FirstLine = 90
; Folding = --
; EnableXP