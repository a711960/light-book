package light.book.script
{
    import flash.events.Event;

    public class ScriptEvent extends Event
    {
        public static const RESULT:String = "SCRIPT_RESULT";
        public var code:String;
        public var level:String;

        public function ScriptEvent(type:String, code:String, level:String)
        {
            super(type, false, false);
            this.code = code;
            this.level = level;
        }


        override public function clone():Event
        {
            return new ScriptEvent(type, code, level);
        }
    }
}
