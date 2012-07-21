package light.book.script
{
    import flash.events.Event;

    /**
     * Script was successfully executed
     */
    public class ScriptResult extends Event
    {
        /**
         * Event type
         */
        public static const RESULT:String = "SCRIPT_RESULT";

        /**
         * Script id
         */
        public var code:int;

        /**
         * Deserialized script "result" variable
         */
        public var result:Object;

        /**
         * Constructor
         * @param type event type
         * @param code script id
         * @param result deserialized script "result" variable
         */
        public function ScriptResult(type:String, code:int, result:Object)
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
            return new ScriptResult(type, code, result);
        }
    }
}
