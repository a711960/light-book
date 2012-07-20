Attribute VB_Name = "Linker"
Option Explicit

Public Sub Main()

   Dim SpecialLink As Boolean, fCPL As Boolean, fResource As Boolean
   Dim intPos As Integer
   Dim strCmd As String
   Dim strPath As String
   Dim strFileContents As String
   Dim strDefFile As String, strResFile As String
   Dim oFS As New Scripting.FileSystemObject
   Dim fld As Folder
   Dim fil As File
   Dim ts As TextStream, tsDef As TextStream

   strCmd = Command
   
   Set ts = oFS.CreateTextFile(App.Path & "\lnklog.txt")
   
   ts.WriteLine "Beginning execution at " & Date & " " & Time()
   ts.WriteBlankLines 1
   ts.WriteLine "Command line arguments to LINK call:"
   ts.WriteBlankLines 1
   ts.WriteLine "   " & strCmd
   ts.WriteBlankLines 2
   
   ' Determine if .DEF file exists
   '
   ' Extract path from first .obj argument
   intPos = InStr(1, strCmd, ".OBJ", vbTextCompare)
   strPath = Mid(strCmd, 2, intPos + 2)
   intPos = InStrRev(strPath, "\")
   strPath = Left(strPath, intPos - 1)
   ' Open folder
   Set fld = oFS.GetFolder(strPath)
   
   ' Get files in folder
   For Each fil In fld.Files
      If UCase(oFS.GetExtensionName(fil)) = "DEF" Then
         strDefFile = fil
         SpecialLink = True
      End If
      If UCase(oFS.GetExtensionName(fil)) = "RES" Then
         strResFile = fil
         fResource = True
      End If
      If SpecialLink And fResource Then Exit For
   Next
      
   ' Change command line arguments if flag set
   If SpecialLink Then
      ' Determine contents of .DEF file
      Set tsDef = oFS.OpenTextFile(strDefFile)
      strFileContents = tsDef.ReadAll
      If InStr(1, strFileContents, "CplApplet", vbTextCompare) > 0 Then
         fCPL = True
      End If
      
      ' Add module definition before /DLL switch
      intPos = InStr(1, strCmd, "/DLL", vbTextCompare)
      If intPos > 0 Then
         strCmd = Left(strCmd, intPos - 1) & _
               " /DEF:" & Chr(34) & strDefFile & Chr(34) & " " & _
               Mid(strCmd, intPos)
      End If
      ' Include .RES file if one exists
      If fResource Then
         intPos = InStr(1, strCmd, "/ENTRY", vbTextCompare)
         strCmd = Left(strCmd, intPos - 1) & Chr(34) & strResFile & _
                  Chr(34) & " " & Mid(strCmd, intPos)
      End If
      
      ' If Control Panel applet, change "DLL" extension to "CPL"
      If fCPL Then
         strCmd = Replace(strCmd, ".dll", ".cpl", 1, , vbTextCompare)
      End If
      
      ' Write linker options to output file
      ts.WriteLine "Command line arguments after modification:"
      ts.WriteBlankLines 1
      ts.WriteLine "   " & strCmd
      ts.WriteBlankLines 2
   End If
   
   ts.WriteLine "Calling LINK.EXE linker"
   Shell "linklnk.exe " & strCmd
   If Err.Number <> 0 Then
      ts.WriteLine "Error in calling linker..."
      Err.Clear
   End If
   
   ts.WriteBlankLines 1
   ts.WriteLine "Returned from linker call"
   ts.Close
End Sub

