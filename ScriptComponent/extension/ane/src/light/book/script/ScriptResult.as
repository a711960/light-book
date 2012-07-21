package light.book.script
{
    import flash.events.Event;

    public class ScriptResult extends Event
    {
        public static const RESULT:String = "SCRIPT_RESULT";
        public var code:int;
        public var result:Object;

        public function ScriptResult(type:String, code:int, result:Object)
        {
            super(type, false, false);
            this.code = code;
            this.result = result;
        }

        override public function clone():Event
        {
            return new ScriptResult(type, code, result);
        }
    }
}
