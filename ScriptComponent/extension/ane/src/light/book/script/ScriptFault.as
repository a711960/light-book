package light.book.script
{
    import flash.events.ErrorEvent;
    import flash.events.Event;

    public class ScriptFault extends ErrorEvent
    {
        public static const FAULT:String = "SCRIPT_FAULT";
        
        public var error:ScriptError;
        public var code:int;

        public function ScriptFault(type:String, code:int, error:ScriptError)
        {
            super(type, false, false);
            this.code = code;
            this.error = error;
            this.text = error.toString();
        }

        override public function clone():Event
        {
            var scriptFault:ScriptFault = new ScriptFault(type, code, error);
            scriptFault.text = text;
            return scriptFault;
        }
    }
}
