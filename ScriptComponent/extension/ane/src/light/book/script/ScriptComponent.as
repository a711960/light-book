package light.book.script
{
    import by.blooddy.crypto.serialization.JSON;

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

        private function execute(code:int, async:Boolean, vbs:Boolean, timeout:int, jsonData:String, script:String):String
        {
            if (!contextCreated)
                return '{"line":0, "number":1, "Class":"light.book.script.ScriptError"}';

            var result:String = null;

            try
            {
                result = _context.call("execute", code, async, vbs, timeout, jsonData, script) as String;
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}, {1}, {2}, {3}, {4}, {5}, {6}), stacktrace: {7}", code, async, vbs, timeout, jsonData, script, e.getStackTrace());
                return '{"line":0, "number":1, "Class":"light.book.script.ScriptError"}'
            }
            return result;
        }

        public function executeAsync(vbs:Boolean, timeout:int, data:Object, script:String):int
        {
            var code:int = Math.round(Math.random() * 100000);
            var jsonData:String = by.blooddy.crypto.serialization.JSON.encode(data);
            var result:String = execute(code, true, vbs,  timeout, jsonData, script);
            var resultObject:Object = by.blooddy.crypto.serialization.JSON.decode(result);
            if(ScriptError.isError(resultObject))
            {
                var scriptError:ScriptError = new ScriptError(resultObject);
                if(scriptError.number != 0)
                {
                    dispatchEvent(new ScriptFault(ScriptFault.FAULT, code, scriptError));
                }
            }
            return code;
        }

        public function executeSync(vbs:Boolean, timeout:int, data:Object, script:String):Object
        {
            var code:int = Math.round(Math.random() * 100000);
            var jsonData:String = by.blooddy.crypto.serialization.JSON.encode(data);
            var result:String = execute(code, false, vbs,  timeout, jsonData, script);
            var resultObject:Object = by.blooddy.crypto.serialization.JSON.decode(result);
            if(ScriptError.isError(resultObject))
            {
                var scriptError:ScriptError = new ScriptError(resultObject);
                if(scriptError.number != 0)
                {
                    dispatchEvent(new ScriptFault(ScriptFault.FAULT, code, scriptError));
                }
            }
            return resultObject;
        }

        private function onStatusEvent(event:StatusEvent):void
        {
            if(Log.isDebug())
                log.info("Status event received: contextType={0} level={2}, code={1}", this.contextType, event.code, event.level);
            var code:int = parseInt(event.code);
            var resultObject:Object = by.blooddy.crypto.serialization.JSON.decode(event.level);
            if(ScriptError.isError(resultObject))
            {
                var scriptError:ScriptError = new ScriptError(resultObject);
                if(scriptError.number != 0)
                {
                    dispatchEvent(new ScriptFault(ScriptFault.FAULT, code, scriptError));
                }
                else
                {
                    dispatchEvent(new ScriptResult(ScriptResult.RESULT, code, resultObject));
                }
            }
            else
            {
                dispatchEvent(new ScriptResult(ScriptResult.RESULT, code, resultObject));
            }
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
                log.debug("Disposed {0}", this.contextType);
            }
            else
            {
                log.warn("Can not dispose {0}: Context is null", this.contextType);
            }
        }
    }
}
