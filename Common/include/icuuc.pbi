EnableExplicit

ImportC "icuuc.lib"
  ;-- int 	ucnv_compareNames (const char *name1, const char *name2)
  ;  	Do a fuzzy compare of two converter/alias names.
  ucnv_compareNames_49.l(name1.l, name2.l)

  ;-- UConverter * 	ucnv_open (const char *converterName, UErrorCode *err)
  ;  	Creates a UConverter object With the name of a coded character set specified As a C string.
  ucnv_open_49.l(converterName.l, err.l)

; UConverter * 	ucnv_openU (const UChar *name, UErrorCode *err)
;  	Creates a Unicode converter With the names specified As unicode string.
; UConverter * 	ucnv_openCCSID (int32_t codepage, UConverterPlatform platform, UErrorCode *err)
;  	Creates a UConverter object from a CCSID number And platform pair.
; UConverter * 	ucnv_openPackage (const char *packageName, const char *converterName, UErrorCode *err)
; UConverter * 	ucnv_safeClone (const UConverter *cnv, void *stackBuffer, int32_t *pBufferSize, UErrorCode *status)
;  	Thread safe converter cloning operation.

  ;-- void 	ucnv_close (UConverter *converter)
  ;  	Deletes the unicode converter And releases resources associated With just this instance.
  ucnv_close_49(converter.l)

; void 	ucnv_getSubstChars (const UConverter *converter, char *subChars, int8_t *len, UErrorCode *err)
;  	Fills in the output parameter, subChars, With the substitution characters As multiple bytes.
; void 	ucnv_setSubstChars (UConverter *converter, const char *subChars, int8_t len, UErrorCode *err)
;  	Sets the substitution chars when converting from unicode To a codepage.
; void 	ucnv_setSubstString (UConverter *cnv, const UChar *s, int32_t length, UErrorCode *err)
;  	Set a substitution string For converting from Unicode To a charset.
; void 	ucnv_getInvalidChars (const UConverter *converter, char *errBytes, int8_t *len, UErrorCode *err)
;  	Fills in the output parameter, errBytes, With the error characters from the last failing conversion.
; void 	ucnv_getInvalidUChars (const UConverter *converter, UChar *errUChars, int8_t *len, UErrorCode *err)
;  	Fills in the output parameter, errChars, With the error characters from the last failing conversion.
; void 	ucnv_reset (UConverter *converter)
;  	Resets the state of a converter To the Default state.
; void 	ucnv_resetToUnicode (UConverter *converter)
;  	Resets the To-Unicode part of a converter state To the Default state.
; void 	ucnv_resetFromUnicode (UConverter *converter)
;  	Resets the from-Unicode part of a converter state To the Default state.
; int8_t 	ucnv_getMaxCharSize (const UConverter *converter)
;  	Returns the maximum number of bytes that are output per UChar in conversion from Unicode using this converter.
; int8_t 	ucnv_getMinCharSize (const UConverter *converter)
;  	Returns the minimum byte length For characters in this codepage.
; int32_t 	ucnv_getDisplayName (const UConverter *converter, const char *displayLocale, UChar *displayName, int32_t displayNameCapacity, UErrorCode *err)
;  	Returns the display name of the converter passed in based on the Locale passed in.
; const char * 	ucnv_getName (const UConverter *converter, UErrorCode *err)
;  	Gets the internal, canonical name of the converter (zero-terminated).
; int32_t 	ucnv_getCCSID (const UConverter *converter, UErrorCode *err)
;  	Gets a codepage number associated With the converter.
; UConverterPlatform 	ucnv_getPlatform (const UConverter *converter, UErrorCode *err)
;  	Gets a codepage platform associated With the converter.
; UConverterType 	ucnv_getType (const UConverter *converter)
;  	Gets the type of the converter e.g.
; void 	ucnv_getStarters (const UConverter *converter, UBool starters[256], UErrorCode *err)
;  	Gets the "starter" (lead) bytes For converters of type MBCS.
; void 	ucnv_getUnicodeSet (const UConverter *cnv, USet *setFillIn, UConverterUnicodeSet whichSet, UErrorCode *pErrorCode)
;  	Returns the set of Unicode code points that can be converted by an ICU converter.
; void 	ucnv_getToUCallBack (const UConverter *converter, UConverterToUCallback *action, const void **context)
;  	Gets the current calback function used by the converter when an illegal Or invalid codepage sequence is found.
; void 	ucnv_getFromUCallBack (const UConverter *converter, UConverterFromUCallback *action, const void **context)
;  	Gets the current callback function used by the converter when illegal Or invalid Unicode sequence is found.
; void 	ucnv_setToUCallBack (UConverter *converter, UConverterToUCallback newAction, const void *newContext, UConverterToUCallback *oldAction, const void **oldContext, UErrorCode *err)
;  	Changes the callback function used by the converter when an illegal Or invalid sequence is found.
; void 	ucnv_setFromUCallBack (UConverter *converter, UConverterFromUCallback newAction, const void *newContext, UConverterFromUCallback *oldAction, const void **oldContext, UErrorCode *err)
;  	Changes the current callback function used by the converter when an illegal Or invalid sequence is found.
; void 	ucnv_fromUnicode (UConverter *converter, char **target, const char *targetLimit, const UChar **source, const UChar *sourceLimit, int32_t *offsets, UBool flush, UErrorCode *err)
;  	Converts an Array of unicode characters To an Array of codepage characters.

  ;-- void 	ucnv_toUnicode (UConverter *converter, UChar **target, const UChar *targetLimit, const char **source, const char *sourceLimit, int32_t *offsets, UBool flush, UErrorCode *err)
  ;  	Converts a buffer of codepage bytes into an Array of unicode UChars characters.
  ucnv_toUnicode_49(converter.l, target.l, targetLimit.l, source.l, sourceLimit.l, offsets.l, flush.l, err.l)
  
; int32_t 	ucnv_fromUChars (UConverter *cnv, char *dest, int32_t destCapacity, const UChar *src, int32_t srcLength, UErrorCode *pErrorCode)
;  	Convert the Unicode string into a codepage string using an existing UConverter.
; int32_t 	ucnv_toUChars (UConverter *cnv, UChar *dest, int32_t destCapacity, const char *src, int32_t srcLength, UErrorCode *pErrorCode)
;  	Convert the codepage string into a Unicode string using an existing UConverter.
; UChar32 	ucnv_getNextUChar (UConverter *converter, const char **source, const char *sourceLimit, UErrorCode *err)
;  	Convert a codepage buffer into Unicode one character at a time.
; void 	ucnv_convertEx (UConverter *targetCnv, UConverter *sourceCnv, char **target, const char *targetLimit, const char **source, const char *sourceLimit, UChar *pivotStart, UChar **pivotSource, UChar **pivotTarget, const UChar *pivotLimit, UBool reset, UBool flush, UErrorCode *pErrorCode)

  ;  	Convert from one external charset To another using two existing UConverters.
  ; int32_t 	ucnv_convert (const char *toConverterName, const char *fromConverterName, char *target, int32_t targetCapacity, const char *source, int32_t sourceLength, UErrorCode *pErrorCode)
  ucnv_convert_49.l(toConverterName.l, fromConverterName.l, target.l, targetCapacity.l, source.l, sourceLength.l, pErrorCode.l)
  
;  	Convert from one external charset To another.
; int32_t 	ucnv_toAlgorithmic (UConverterType algorithmicType, UConverter *cnv, char *target, int32_t targetCapacity, const char *source, int32_t sourceLength, UErrorCode *pErrorCode)
;  	Convert from one external charset To another.
; int32_t 	ucnv_fromAlgorithmic (UConverter *cnv, UConverterType algorithmicType, char *target, int32_t targetCapacity, const char *source, int32_t sourceLength, UErrorCode *pErrorCode)
;  	Convert from one external charset To another.
; int32_t 	ucnv_flushCache (void)
;  	Frees up memory occupied by unused, cached converter Shared Data.
; int32_t 	ucnv_countAvailable (void)
;  	Returns the number of available converters, As per the alias file.
; const char * 	ucnv_getAvailableName (int32_t n)
;  	Gets the canonical converter name of the specified converter from a List of all available converters contaied in the alias file.
; UEnumeration * 	ucnv_openAllNames (UErrorCode *pErrorCode)
;  	Returns a UEnumeration To enumerate all of the canonical converter names, As per the alias file, regardless of the ability To open each converter.
; uint16_t 	ucnv_countAliases (const char *alias, UErrorCode *pErrorCode)
;  	Gives the number of aliases For a given converter Or alias name.
; const char * 	ucnv_getAlias (const char *alias, uint16_t n, UErrorCode *pErrorCode)
;  	Gives the name of the alias at given index of alias List.
; void 	ucnv_getAliases (const char *alias, const char **aliases, UErrorCode *pErrorCode)
;  	Fill-up the List of alias names For the given alias.
; UEnumeration * 	ucnv_openStandardNames (const char *convName, const char *standard, UErrorCode *pErrorCode)
;  	Return a new UEnumeration object For enumerating all the alias names For a given converter that are recognized by a standard.
; uint16_t 	ucnv_countStandards (void)
;  	Gives the number of standards associated To converter names.
; const char * 	ucnv_getStandard (uint16_t n, UErrorCode *pErrorCode)
;  	Gives the name of the standard at given index of standard List.
; const char * 	ucnv_getStandardName (const char *name, const char *standard, UErrorCode *pErrorCode)
;  	Returns a standard name For a given converter name.
; const char * 	ucnv_getCanonicalName (const char *alias, const char *standard, UErrorCode *pErrorCode)
;  	This function will Return the internal canonical converter name of the tagged alias.
; const char * 	ucnv_getDefaultName (void)
;  	Returns the current Default converter name.
; void 	ucnv_setDefaultName (const char *name)
;  	This function is Not thread safe.
; void 	ucnv_fixFileSeparator (const UConverter *cnv, UChar *source, int32_t sourceLen)
;  	Fixes the backslash character mismapping.
; UBool 	ucnv_isAmbiguous (const UConverter *cnv)
;  	Determines If the converter contains ambiguous mappings of the same character Or Not.
; void 	ucnv_setFallback (UConverter *cnv, UBool usesFallback)
;  	Sets the converter To use fallback mappings Or Not.
; UBool 	ucnv_usesFallback (const UConverter *cnv)
;  	Determines If the converter uses fallback mappings Or Not.
; const char * 	ucnv_detectUnicodeSignature (const char *source, int32_t sourceLength, int32_t *signatureLength, UErrorCode *pErrorCode)
;  	Detects Unicode signature byte sequences at the start of the byte stream And returns the charset name of the indicated Unicode charset.
; int32_t 	ucnv_fromUCountPending (const UConverter *cnv, UErrorCode *status)
;  	Returns the number of UChars held in the converter's internal state because more input is needed for completing the conversion.
; int32_t 	ucnv_toUCountPending (const UConverter *cnv, UErrorCode *status)
;  	Returns the number of chars held in the converter's internal state because more input is needed for completing the conversion.
; UBool 	ucnv_isFixedWidth (UConverter *cnv, UErrorCode *status)
;  	Returns whether Or Not the charset of the converter has a fixed number of bytes per charset character. 
EndImport
; IDE Options = PureBasic 4.61 (Windows - x86)
; EnableXP