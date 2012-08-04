package light.book.lucene
{
    import flash.events.ErrorEvent;
    import flash.events.Event;

    /**
     * Exiftool was executed with errors (exitCode != 0 or error tag)
     */
    public class LuceneFault extends ErrorEvent
    {
        /**
         * Event type
         */
        public static const FAULT:String = "LUCENE_FAULT";

        /**
         * Error description
         * @see LuceneError
         */
        public var error:LuceneError;

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
        public function LuceneFault(type:String, code:int, error:LuceneError)
        {
            super(type, true, true);
            this.code = code;
            this.error = error;
            this.text = error.toString();
        }

        /**
         * @inheritDoc
         */
        override public function clone():Event
        {
            var scriptFault:LuceneFault = new LuceneFault(type, code, error);
            scriptFault.text = text;
            return scriptFault;
        }
    }
}
