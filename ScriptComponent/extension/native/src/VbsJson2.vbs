'
'	VBS JSON 2.0.3
'	Copyright (c) 2009 Tuрrul Topuz
'	Under the MIT (MIT-LICENSE.txt) license.
'

Const JSON_OBJECT	= 0
Const JSON_ARRAY	= 1

Class jsCore
	Public Collection
	Public Count
	Public QuotedVars
	Public Kind ' 0 = object, 1 = array

	Private Sub Class_Initialize
		Set Collection = CreateObject("Scripting.Dictionary")
		QuotedVars = True
		Count = 0
		Kind = JSON_OBJECT
	End Sub

	Private Sub Class_Terminate
		Set Collection = Nothing
	End Sub

	' counter
	Private Property Get Counter
		Counter = Count
		Count = Count + 1
	End Property

	' - data maluplation
	' -- pair
	Public Property Let Pair(p, v)
		If IsNull(p) Then p = Counter
		Collection(p) = v
	End Property

	Public Property Set Pair(p, v)
		If IsNull(p) Then p = Counter
		If TypeName(v) <> "jsCore" Then
			Err.Raise &hD, "class: class", "Incompatible types: '" & TypeName(v) & "'"
		End If
		Set Collection(p) = v
	End Property

	Public Default Property Get Pair(p)
		If IsNull(p) Then p = Count - 1
		If IsObject(Collection(p)) Then
			Set Pair = Collection(p)
		Else
			Pair = Collection(p)
		End If
	End Property
	' -- pair
	Public Sub Clean
		Collection.RemoveAll
	End Sub

	Public Sub Remove(vProp)
		Collection.Remove vProp
	End Sub
	' data maluplation

	' encoding
	Function jsEncode(str)
		Dim charmap(127), haystack()
		charmap(8)  = "\b"
		charmap(9)  = "\t"
		charmap(10) = "\n"
		charmap(12) = "\f"
		charmap(13) = "\r"
		charmap(34) = "\"""
		charmap(47) = "\/"
		charmap(92) = "\\"

		Dim strlen : strlen = Len(str) - 1
		ReDim haystack(strlen)

		Dim i, charcode
		For i = 0 To strlen
			haystack(i) = Mid(str, i + 1, 1)

			charcode = AscW(haystack(i)) And 65535
			If charcode < 127 Then
				If Not IsEmpty(charmap(charcode)) Then
					haystack(i) = charmap(charcode)
				ElseIf charcode < 32 Then
					haystack(i) = "\u" & Right("000" & Hex(charcode), 4)
				End If
			Else
				haystack(i) = "\u" & Right("000" & Hex(charcode), 4)
			End If
		Next

		jsEncode = Join(haystack, "")
	End Function

	' converting
	Public Function stringify(vPair)
		Select Case VarType(vPair)
			Case 0	' Empty
				stringify = "null"
			Case 1	' Null
				stringify = "null"
			Case 7	' Date
				' stringify = "new Date(" & (vPair - CDate(25569)) * 86400000 & ")"	' let in only utc time
				stringify = """" & CStr(vPair) & """"
			Case 8	' String
				stringify = """" & jsEncode(vPair) & """"
			Case 9	' Object
				Dim bFI,i
				bFI = True
				If vPair.Kind Then stringify = stringify & "[" Else stringify = stringify & "{"
				For Each i In vPair.Collection
					If bFI Then bFI = False Else stringify = stringify & ","

					If vPair.Kind Then
						stringify = stringify & stringify(vPair(i))
					Else
						If QuotedVars Then
							stringify = stringify & """" & i & """:" & stringify(vPair(i))
						Else
							stringify = stringify & i & ":" & stringify(vPair(i))
						End If
					End If
				Next
				If vPair.Kind Then stringify = stringify & "]" Else stringify = stringify & "}"
			Case 11
				If vPair Then stringify = "true" Else stringify = "false"
			Case 12, 8192, 8204
				stringify = RenderArray(vPair, 1, "")
			Case Else
				stringify = Replace(vPair, ",", ".")
		End select
	End Function

	Function RenderArray(arr, depth, parent)
		Dim first : first = LBound(arr, depth)
		Dim last : last = UBound(arr, depth)

		Dim index, rendered
		Dim limiter : limiter = ","

		RenderArray = "["
		For index = first To last
			If index = last Then
				limiter = ""
			End If

			On Error Resume Next
			rendered = RenderArray(arr, depth + 1, parent & index & "," )

			If Err = 9 Then
				On Error GoTo 0
				RenderArray = RenderArray & stringify(Eval("arr(" & parent & index & ")")) & limiter
			Else
				RenderArray = RenderArray & rendered & "" & limiter
			End If
		Next
		RenderArray = RenderArray & "]"
	End Function

	Public Property Get jsString
		jsString = stringify(Me)
	End Property

	Sub Flush
		If TypeName(Response) <> "Empty" Then
			Response.Write(jsString)
		ElseIf WScript <> Empty Then
			WScript.Echo(jsString)
		End If
	End Sub

	Public Function Clone
		Set Clone = ColClone(Me)
	End Function

	Private Function ColClone(core)
		Dim jsc, i
		Set jsc = new jsCore
		jsc.Kind = core.Kind
		For Each i In core.Collection
			If IsObject(core(i)) Then
				Set jsc(i) = ColClone(core(i))
			Else
				jsc(i) = core(i)
			End If
		Next
		Set ColClone = jsc
	End Function

End Class