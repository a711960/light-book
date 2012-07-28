package light.book.exif
{
    import flash.events.ErrorEvent;
    import flash.events.Event;

    /**
     * Exiftool was executed with errors (exitCode <> 0 or error tag)
     */
    public class ExifFault extends ErrorEvent
    {
        /**
         * Event type
         */
        public static const FAULT:String = "EXIF_FAULT";

        /**
         * Error description
         * @see ExifError
         */
        public var error:ExifError;

        /**
         * Script id
         */
        public var code:int;

        /**
         * Constructor
         * @param type event type
         * @param code request id
         * @param error error description
         */
        public function ExifFault(type:String, code:int, error:ExifError)
        {
            super(type, false, false);
            this.code = code;
            this.error = error;
            this.text = error.toString();
        }

        /**
         * @inheritDoc
         */
        override public function clone():Event
        {
            var scriptFault:ExifFault = new ExifFault(type, code, error);
            scriptFault.text = text;
            return scriptFault;
        }
    }
}
