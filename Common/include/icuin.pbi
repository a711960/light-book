EnableExplicit

ImportC "..\..\..\..\Common\lib\icuin.lib"
  ;-- UCharsetDetector * 	ucsdet_open (UErrorCode *status)
  ;  	Open a charset detector.
  ucsdet_open_49.l(status.l)
  
  ;-- void 	ucsdet_close (UCharsetDetector *ucsd)
  ;  	Close a charset detector.
  ucsdet_close_49(ucsd.l)

  ; void 	ucsdet_setText (UCharsetDetector *ucsd, const char *textIn, int32_t len, UErrorCode *status)
  ;  	Set the input byte Data whose charset is To detected.

  ucsdet_setText_49(ucsd.l, textIn.l, len.l, status.l)

  ;-- void 	ucsdet_setDeclaredEncoding (UCharsetDetector *ucsd, const char *encoding, int32_t length, UErrorCode *status)
  ;  	Set the declared encoding For charset detection.
  ucsdet_setDeclaredEncoding_49(ucsd.l, encoding.l, length.l, status.l)

  ;-- const UCharsetMatch * 	ucsdet_detect (UCharsetDetector *ucsd, UErrorCode *status)
  ;  	Return the charset that best matches the supplied input Data.
  ucsdet_detect_49.l(ucsd.l, status.l)

  ;-- const UCharsetMatch ** 	ucsdet_detectAll (UCharsetDetector *ucsd, int32_t *matchesFound, UErrorCode *status)
  ;  	Find all charset matches that appear To be consistent With the input, returning an Array of results.
  ; const char * 	ucsdet_getName (const UCharsetMatch *ucsm, UErrorCode *status)
  
  ucsdet_getName_49.l(ucsm.l, status.l)
  
;  	Get the name of the charset represented by a UCharsetMatch.
; int32_t 	ucsdet_getConfidence (const UCharsetMatch *ucsm, UErrorCode *status)
;  	Get a confidence number For the quality of the match of the byte Data With the charset.
; const char * 	ucsdet_getLanguage (const UCharsetMatch *ucsm, UErrorCode *status)
;  	Get the RFC 3066 code For the language of the input Data.
; int32_t 	ucsdet_getUChars (const UCharsetMatch *ucsm, UChar *buf, int32_t cap, UErrorCode *status)
;  	Get the entire input text As a UChar string, placing it into a caller-supplied buffer.
; UEnumeration * 	ucsdet_getAllDetectableCharsets (const UCharsetDetector *ucsd, UErrorCode *status)
;  	Get an iterator over the set of all detectable charsets - over the charsets that are known To the charset detection service.
; UBool 	ucsdet_isInputFilterEnabled (const UCharsetDetector *ucsd)
;  	Test whether input filtering is enabled For this charset detector.
; UBool 	ucsdet_enableInputFilter (UCharsetDetector *ucsd, UBool filter)

EndImport
; IDE Options = PureBasic 4.61 (Windows - x86)
; EnableXP