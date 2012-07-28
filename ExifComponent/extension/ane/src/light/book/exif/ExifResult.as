package light.book.exif
{
    import flash.events.Event;

    /**
     * Script was successfully executed
     */
    public class ExifResult extends Event
    {
        /**
         * Event type
         */
        public static const RESULT:String = "EXIF_RESULT";

        /**
         * Script id
         */
        public var code:int;

        /**
         * Deserialized exif "result" variable
         */
        public var result:MetaInfo;

        /**
         * Constructor
         * @param type event type
         * @param code exif id
         * @param result deserialized exif "result" variable
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
