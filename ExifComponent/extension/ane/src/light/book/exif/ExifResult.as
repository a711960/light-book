package light.book.exif
{
    import flash.events.Event;

    /**
     * Exiftool was successfully executed
     */
    public class ExifResult extends Event
    {
        /**
         * Event type
         */
        public static const RESULT:String = "EXIF_RESULT";

        /**
         * Request id
         */
        public var code:int;

        /**
         * Extracted metadata
         */
        public var result:MetaInfo;

        /**
         * Constructor
         * @param type event type
         * @param code request id
         * @param result extracted metadata
         */
        public function ExifResult(type:String, code:int, result:MetaInfo)
        {
            super(type, false, false);
            this.code = code;
            this.result = result;
        }

        /**
         * @inheritDoc
         */
        override public function clone():Event
        {
            return new ExifResult(type, code, result);
        }
    }
}
