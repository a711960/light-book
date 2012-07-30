package light.book.exif
{
    /**
     * Provides basic information about errors
     */
    public class ExifError extends Error
    {
        private static const ERROR_PATTERN:RegExp = /error: ([0-9]+)[,]*([^,]*)[,]*([^,]*)[,]*([^,]*)[,]*([^,]*)/i;

        private static const ERROR_DESCRIPTIONS:Object = {
            1: "Failed to convert UTF8 to UCS2",
            2: "Exiftool execution failed",
            3: "AllocateMemory failed",
            4: "Output exceeded maxOutput",
            5: "Output is empty",
            6: "Failed to parse Exiftool output",
            7: "Failed to init ICU",
            8: "Exiftool timed out",
            9: "Failed to get file short path name",
            10: "Failed to convert UCS2 to UTF8",
            100: "Unknown error"
        };

        public static const UNKNOWN:ExifError = new ExifError(ERROR_DESCRIPTIONS[100], 100);

        /**
         * @inheritDoc
         */
        public function ExifError(message:* = "",id:* = 0)
        {
            super(message, id)
        }


        public function toString():String
        {
            return "ExifError{errorID=" + String(this.errorID) + ", message=" + this.message + "}";
        }

        public static function isError(level:String):Boolean
        {
            return level && ERROR_PATTERN.test(level);
        }

        public static function parseError(level:String):ExifError
        {
            var match:Array = ERROR_PATTERN.exec(level);
            var errorID:Number = parseInt(match[1]);
            var message:String = ERROR_DESCRIPTIONS[errorID];
            var exifError:ExifError = new ExifError(message ? format(message, match) : "unknown error", errorID);
            return exifError;
        }

        public static function format(message:String, rest:Array, start:int = 2):String
        {
            for (var i:int = start; i < rest.length; i++)
            {
                message = message.replace(new RegExp("\\{"+(i-start)+"\\}", "g"), rest[i]);
            }
            return message;
        }
    }
}
