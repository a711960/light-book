package light.book.script
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    import mx.logging.ILogger;
    import mx.logging.Log;

    /**
     * Wrapper for PureBasic extension
     */
    public class ScriptComponent extends EventDispatcher
    {
        /**
         * Extension id, must be specified in air-manifest.xml and extension.xml
         */
        public static const CONTEXT:String = "light.book.script.ScriptComponent";

        private static const log:ILogger = Log.getLogger(CONTEXT);

        /**
         * @private
         */
        private var _context:ExtensionContext;

        /**
         * @private
         */
        private var contextType:String;

        /**
         * Creates context
         * @param contextType default value is "PureAir"
         * @param actionScriptData ant number
         */
        public function ScriptComponent(contextType:String = "ScriptComponent")
        {
            //random type
            this.contextType = contextType + Math.round(Math.random() * 100000);
            try
            {
                log.debug("Creating context: {0}, contextType: {1}", CONTEXT, this.contextType);

                _context = ExtensionContext.createExtensionContext(CONTEXT, this.contextType);

                if (_context == null)
                {
                    //creation failed
                    log.error("Failed to create context: {0}, contextType: {1}", CONTEXT, this.contextType);
                }
                else
                {
                    log.debug("Context was created successfully");

                    //listen for extension events
                    _context.addEventListener(StatusEvent.STATUS, onStatusEvent);
                }
            }
            catch(e:Error)
            {
                log.error("Failed to create context: {0}, contextType: {1}, stacktrace: {2}", CONTEXT, this.contextType, e.getStackTrace());
            }
        }

        private function get contextCreated():Boolean
        {
            return _context != null;
        }

        public function execute(code:int, async:Boolean, jsonParameters:String, jsonInjectData:String):Boolean
        {
            if (!contextCreated)
                return false;

            var result:Boolean = false;

            try
            {
                result = _context.call('execute', code, async, jsonParameters, jsonInjectData) as Boolean;
                if (!result)
                {
                    log.error("Invocation error: execute({0}, {1}, {2}, {3})", code, async, jsonParameters, jsonInjectData);
                }
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}, {1}, {2}, {3}), stacktrace: {4}", code, async, jsonParameters, jsonInjectData, e.getStackTrace());
            }
            return result;
        }


        private function onStatusEvent(event:StatusEvent):void
        {
            log.info("Status event received: contextType={0} level={2}, code={1}", this.contextType, event.code, event.level);
            dispatchEvent(new ScriptEvent(ScriptEvent.RESULT, event.code, event.level));
        }

        /**
         * Performs clean-up
         */
        public function dispose():void
        {
            if (_context)
            {
                _context.dispose();
                //clean all references
                _context.removeEventListener(StatusEvent.STATUS, onStatusEvent);
                _context = null;
                log.info("Disposed {0}", this.contextType);
            }
            else
            {
                log.warn("Can not dispose {0}: Context is null", this.contextType);
            }
        }
    }
}
