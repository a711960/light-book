package light.book.script
{
    /**
     * Provides basic information about script errors
     */
    public class ScriptError extends Error
    {
        /**
         * @Private
         */
        private static const CLASS:String = "Class";

        /**
         * @Private
         */
        private static const CLASS_NAME:String = "error";

        /**
         * @Private
         */
        public static const ERROR_CODES:Object = {0: "No error",
            1: "Script error",
            2: "Failed to create BSTR",
            3: "Failed to create MS ScriptControl",
            4: "Failed to create script object",
            100: "Unknown error"
            };
        /**
         * Error line
         */
        public var line:Number = 0;
        public var scripterror:Number = 0;
        public var description:String = "";

        /**
         * Constructor
         * @param object deserialized from extension JSON response
         */
        public function ScriptError(errorID:Number,  message:String)
        {
            super(message, errorID);
        }

        /**
         * Test if deserialized object is ScriptError
         * @param object
         * @return
         */
        public static function isError(object:Object):Boolean
        {
             return object == null || !object.hasOwnProperty(CLASS) || (CLASS_NAME == object[CLASS]);
        }

        public static function parseError(object:Object):ScriptError
        {
            var exifError:ScriptError;
            
            if(object)
            {
                var errorID:Number = object.number;
                var scripterror:Number = object.scripterror;
                var line:Number = object.line;
                var description:String = object.description;
                var message:String = errorID != 1 ? ERROR_CODES[errorID] : "Script error: #" + scripterror + ", line: " + line + ", description: " + description;
                exifError = new ScriptError(errorID, message);
                exifError.line = line;
                exifError.description = description;
                exifError.scripterror = scripterror;
            }
            else
            {
                exifError = new ScriptError(100,  ERROR_CODES[100]);
            }
            return exifError;
        }
        
        public function toString():String
        {
            var message:String = errorID != 1 ? ERROR_CODES[errorID] : "Script error: #" + scripterror + ", line: " + line + ", description: " + description;
            return "ScriptError{errorID=" + String(errorID) + ", message=" + String(message) + "}";
        }
    }
}
