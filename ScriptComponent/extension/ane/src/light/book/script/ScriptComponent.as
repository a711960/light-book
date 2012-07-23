package light.book.script
{
    //Much faster serialization using Haxe
    import by.blooddy.crypto.serialization.JSON;

    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    import mx.logging.ILogger;
    import mx.logging.Log;

    /**
     * Script was executed with errors
     */
    [Event(name="SCRIPT_RESULT", type="light.book.script.ScriptResult")]

    /**
     * Script was successfully executed
     */
    [Event(name="SCRIPT_FAULT", type="light.book.script.ScriptFault")]

    /**
     * <p>ScriptComponent extension, interface to MS ScriptComponent</p>
     *
     * <p>Data objects are serialized to JSON and then are available in script via
     * <b>args</b> variable</p>
     *
     * <p>JSON parsers are automatically embedded in script:
     *
     * <ul>
     * <li>VBScript: <a href="http://demon.tw/my-work/vbs-json.html">http://demon.tw/my-work/vbs-json.html</a></li>
     * <li>JScript: <a href="https://github.com/douglascrockford/JSON-js/">https://github.com/douglascrockford/JSON-js/</a></li>
     * </ul>
     *
     * Loopback example:
     * <pre>
     *    Dim o
     *    Set o = args 'args contains parsed data from Air
     *    o.add "key", "value"
     *    Return o  ' Return is a function
     * </pre>
     * </p>
     */
    public class ScriptComponent extends EventDispatcher
    {
        /**
         * Extension id, must be specified in air-manifest.xml and extension.xml
         */
        public static const CONTEXT:String = "light.book.script.ScriptComponent";

        /**
         * @private
         */
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
         * Constructor
         * @param contextType default value is "ScriptComponent"
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

        /**
         * @private
         */
        private function get contextCreated():Boolean
        {
            return _context != null;
        }

        /**
         * @private
         */
        private function execute(code:int, async:Boolean, vbs:Boolean, timeout:int, allowUI:Boolean, jsonData:String, script:String):String
        {
            if (!contextCreated)
                return '{"line":0, "number":1, "Class":"error"}';

            var result:String = null;

            try
            {
                result = _context.call("execute", code, async, vbs, timeout, allowUI, jsonData, script) as String;
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}), stacktrace: {8}", code, async, vbs, timeout, allowUI, jsonData, script, e.getStackTrace());
                return '{"line":0, "number":1, "Class":"error"}'
            }
            return result;
        }


        /**
         * Execute script asynchronously
         * @param vbs is language VBScript(true) or JScript(false)
         * @param timeout length of time in milliseconds that a script can execute before being considered hung
         * @param allowUI Enable or disable display of the UI
         * @param data properties passed to script, serialized to JSON, available through <b>parameters.items("arguments")</b>
         * @param script script to be executed
         * @return script id
         * @see ScriptResult
         * @see ScriptFault
         */
        public function executeAsync(vbs:Boolean, timeout:int, allowUI:Boolean, data:Object, script:String):int
        {
            var code:int = Math.round(Math.random() * 100000);
            var jsonData:String = by.blooddy.crypto.serialization.JSON.encode(data);
            var result:String = execute(code, true, vbs,  timeout, allowUI, jsonData, script);
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

        /**
         * Execute script immediately
         * @param vbs is language VBScript(true) or JScript(false)
         * @param timeout length of time in milliseconds that a script can execute before being considered hung
         * @param allowUI Enable or disable display of the UI
         * @param data properties passed to script, serialized to JSON, available through <b>parameters.items("arguments")</b>
         * @param script script to be executed
         * @return deserialized script "result" variable
         */
        public function executeSync(vbs:Boolean, timeout:int, allowUI:Boolean, data:Object, script:String):Object
        {
            var code:int = Math.round(Math.random() * 100000);
            var jsonData:String = by.blooddy.crypto.serialization.JSON.encode(data);
            var result:String = execute(code, false, vbs,  timeout, allowUI, jsonData, script);
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

        /**
         * @private
         */
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
