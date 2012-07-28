EnableExplicit

XIncludeFile "icuin.pbi"
XIncludeFile "icuuc.pbi"

#Win = 0
#Editor01 = 1
#BtnGet = 2

Define igEventGadget.i = 0
Define igEvent.i = 0
Define igExit.i = 0

Structure Tag
  line_begin.l
  line_size.l
  value_begin.l
  value_size.l
EndStructure

Structure TagKeyValue
  value.l
  valueSize.l
  key.l
  keySize.l
EndStructure
         
Procedure.s GetAppText()
  Define key.b = Asc(":")
  
  Define Compiler.i = RunProgram("exiftool.exe", "c:\Users\Dookie\Desktop\exif\test.fb2", "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  Define *stdout = AllocateMemory(131072)
  If Compiler
    Define offset.l = 0
    Define size.l = 0
    While ProgramRunning(Compiler)
      size = AvailableProgramOutput(Compiler)
      If(size > 0)
        ReadProgramData(Compiler, *stdout + offset, size)
        offset = offset + size
      EndIf
    Wend
    
    Define exitCode.l = ProgramExitCode(Compiler)
    Debug "exitCode = " + Str(exitCode)
    
    If exitCode <> 0
      ProcedureReturn ""
    EndIf
    
    Debug "output size: " + Str(offset)
    Dim outlines.Tag(100)
    Dim tags.TagKeyValue(100)
    Define i.l, n.l, prev.l
    Define tagName.s
    
    For i = 1 To offset-1
      Define b1.b = PeekB(*stdout + i - 1)
      Define b2.b = PeekB(*stdout + i)
      
      If(b1 = Asc(#CR$) And b2 = Asc(#LF$))
        outlines(n)\line_begin = *stdout + prev
        outlines(n)\line_size = i - prev
        Define m.l
        For m = 1 To (i - prev)
          Define c.b = PeekB(*stdout + prev + m)
          If(c = key)
            Break
          EndIf
        Next
        outlines(n)\value_begin = *stdout + (prev + m + 2)
        outlines(n)\value_size = i - (prev + m + 2)
        
        tags(n)\key = outlines(n)\line_begin
        tags(n)\keySize = m
        n = n + 1
        prev = i
      EndIf
    Next
    CloseProgram(Compiler) ; Close the connection to the program
  EndIf
  
  Debug "Line count: " + Str(n)
  

  Define status.l, ucsd.l, ucsm.l, *name, name.s, sub.s, matches.s
  ucsd = ucsdet_open_49(@status)
  Debug "ucsd(" + Str(ucsd) + ") status(" + Str(status) + ")"
  
  Define l.l, value_begin.l, value_size.l
  For l=0 To n - 1
    
    value_begin = outlines(l)\value_begin
    value_size = outlines(l)\value_size
    
   
    Debug "start " + Str(value_begin)
    Debug "end " + Str(value_begin + value_size)
    
    Debug Chr(PeekA(value_begin))
    Debug PeekS(value_begin, value_size, #PB_Ascii)
    Debug PeekS(tags(l)\key, tags(l)\keySize, #PB_Ascii)
    
    ucsdet_setText_49(ucsd, value_begin, value_size, @status)
    Debug "ucsdet_setText_49 status(" + Str(status) + ")"
    
    ucsm = ucsdet_detect_49(ucsd, @status)
    Debug "ucsm(" + Str(ucsm) + ") status(" + Str(status) + ")"
    
    If ucsm <> 0
      *name = ucsdet_getName_49(ucsm, @status)
      name = PeekS(*name, -1, #PB_Ascii)
      ; convert To name
      Define *target = AllocateMemory(4000)
      Define converted.l
      converted = ucnv_convert_49(@"utf-8", *name, *target, 4000, value_begin, value_size, @status)
      Debug "ucnv_convert_49 (" + Str(status) + ")"
      Debug "converted size = " + Str(converted)
      tags(l)\valueSize = converted
      Define lines.s
      If converted > 0
        lines = PeekS(*target, -1, #PB_UTF8)
        tags(l)\value = AllocateMemory(converted)
        CopyMemory(*target, tags(l)\value, converted)
      EndIf
      FreeMemory(*target)
      Debug "converted: '" + lines + "'"
    Else
      name = "unknown"
    EndIf
    Debug "ucsdet_getName_49 [" + name + "] status(" + Str(status) + ")"
    
    matches = matches + "'" + lines  +  "' Charset => " + name + #CRLF$
  Next
  
  ucsdet_close_49(ucsd)  
  
  FreeMemory(*stdout)
  
  For l=0 To n - 1
    If(tags(l)\valueSize > 0)
      OpenFile(1, "./out/tag" + Str(l) + ".txt")
      WriteData(1, tags(l)\value, tags(l)\valueSize)
      CloseFile(1)
      FreeMemory(tags(l)\value)
    EndIf
  Next

  ProcedureReturn matches 
EndProcedure

Procedure OpenWin()
;------------------
  If OpenWindow(#Win, 0, 0, 380, 360, "Get Text",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)

               EditorGadget(#Editor01, 10, 10, 360, 300)
               ButtonGadget(#BtnGet,   10, 320,360, 25, "Get Text")
               SendMessage_(GadgetID(#Editor01), #EM_SETTARGETDEVICE, #Null, 0) ;## WordWrap on

  EndIf

EndProcedure

OpenWin()

Repeat
                 igEvent = WaitWindowEvent(1)
          Select igEvent

                    Case #PB_Event_Gadget

                                   igEventGadget = EventGadget()
                            Select igEventGadget

                                      Case #BtnGet : Define sAppText.s = GetAppText() : SetGadgetText(#Editor01,sAppText)

                            EndSelect

                    Case #PB_Event_CloseWindow : igExit = #PB_Event_CloseWindow

          EndSelect

Until igExit = #PB_Event_CloseWindow

End
; IDE Options = PureBasic 4.61 (Windows - x86)
; CursorPosition = 74
; FirstLine = 81
; Folding = -
; EnableUnicode
; EnableXP