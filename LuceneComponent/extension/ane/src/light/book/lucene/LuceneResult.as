package light.book.lucene
{
    import flash.events.Event;

    /**
     * Exiftool was successfully executed
     */
    public class LuceneResult extends Event
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
        public var result:Array;

        /**
         * Constructor
         * @param type event type
         * @param code request id
         * @param result extracted metadata
         */
        public function LuceneResult(type:String, code:int, result:Array)
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
            return new LuceneResult(type, code, result);
        }
    }
}
