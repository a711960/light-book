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

        private static const ERROR_JSON:String = '{"line":0, "number":1, "Class":"error"}';

        /**
         * @private
         */
        private function execute(code:int, async:Boolean, vbs:Boolean, timeout:int, allowUI:Boolean, safeSubset:Boolean, jsonData:String, script:String):String
        {
            if (!contextCreated)
                return ERROR_JSON;

            var result:String = null;

            try
            {
                result = _context.call("execute", code, async, vbs, timeout, allowUI, safeSubset, jsonData, script) as String;
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}), stacktrace: {9}", code, async, vbs, timeout, allowUI, safeSubset, jsonData, script, e.getStackTrace());
                return ERROR_JSON
            }
            return result;
        }


        /**
         * Execute script asynchronously
         * @param language is language VBScript(ScriptEngine.VBScript) or JScript(ScriptEngine.JScript)
         * @param timeout length of time in milliseconds that a script can execute before being considered hung
         * @param allowUI enable or disable display of the UI
         * @param safeSubset force script to execute in safe mode and disallow potentially harmful actions
         * @param data properties passed to script, serialized to JSON, available through <b>parameters.items("arguments")</b>
         * @param script script to be executed
         * @return script id
         *
         * @see ScriptResult
         * @see ScriptFault
         */
        public function executeAsync(script:String, data:Object = null, language:int = ScriptEngine.VBScript, timeout:int = 15000, allowUI:Boolean = true, safeSubset:Boolean = false):int
        {
            var code:int = Math.round(Math.random() * 100000);
             try
            {
                var jsonData:String = by.blooddy.crypto.serialization.JSON.encode(data);
                var result:String = execute(code, true, ScriptEngine.VBScript == language, timeout, allowUI, safeSubset, jsonData, script);
                var resultObject:Object = by.blooddy.crypto.serialization.JSON.decode(result);
                if (ScriptError.isError(resultObject))
                {
                    dispatchEvent(new ScriptFault(ScriptFault.FAULT, code, new ScriptError(resultObject)));
                }
            }
            catch (e:Error)
            {
                log.error("Serialization error: {0}: {1}", e.errorID, e.message);
                resultObject = {Class:"error", number:1};
            }
            return code;
        }

        /**
         * Execute script immediately
         * @param language is language VBScript(ScriptEngine.VBScript) or JScript(ScriptEngine.JScript)
         * @param timeout length of time in milliseconds that a script can execute before being considered hung
         * @param allowUI enable or disable display of the UI
         * @param safeSubset force script to execute in safe mode and disallow potentially harmful actions
         * @param data properties passed to script, serialized to JSON, available through <b>parameters.items("arguments")</b>
         * @param script script to be executed
         * @return deserialized script "result" variable
         *
         * @throws ScriptError
         */
        public function executeSync(script:String, data:Object = null, language:int = ScriptEngine.VBScript, timeout:int = 15000, allowUI:Boolean = true, safeSubset:Boolean = false):Object
        {
            var code:int = Math.round(Math.random() * 100000);
            try
            {
                var jsonData:String = by.blooddy.crypto.serialization.JSON.encode(data);
                var result:String = execute(code, false, ScriptEngine.VBScript == language, timeout, allowUI, safeSubset, jsonData, script);
                var resultObject:Object;
                resultObject = by.blooddy.crypto.serialization.JSON.decode(result);
            }
            catch (e:Error)
            {
                log.error("Serialization error: {0}: {1}", e.errorID, e.message);
                resultObject = {Class:"error", number:1};
            }
            if (ScriptError.isError(resultObject))
            {
                throw new ScriptError(resultObject);
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
            var resultObject:Object;
            try
            {
                resultObject = by.blooddy.crypto.serialization.JSON.decode(event.level);
            }
            catch(e:Error)
            {
                log.error("Deserialization error: {0}: {1}", e.errorID, e.message);
                resultObject = {Class: "error", number: 1};
            }
            if(ScriptError.isError(resultObject))
            {
                dispatchEvent(new ScriptFault(ScriptFault.FAULT, code, new ScriptError(resultObject)));
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
