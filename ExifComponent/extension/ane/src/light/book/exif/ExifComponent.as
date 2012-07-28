package light.book.exif
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    import mx.logging.ILogger;
    import mx.logging.Log;
    import mx.utils.ObjectUtil;

    /**
     * Script was executed with errors
     */
    [Event(name="EXIF_RESULT", type="light.book.exif.ExifResult")]

    /**
     * Script was successfully executed
     */
    [Event(name="EXIF_FAULT", type="light.book.exif.ExifFault")]

    /**
     * <p>ScriptComponent extension, interface to MS ScriptComponent</p>
     *
     * <p>Data objects are serialized to JSON and then are available in exif via
     * <b>args</b> variable</p>
     *
     * <p>JSON parsers are automatically embedded in exif:
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
    public class ExifComponent extends EventDispatcher
    {
        /**
         * Extension id, must be specified in air-manifest.xml and extension.xml
         */
        public static const CONTEXT:String = "light.book.exif.ExifComponent";

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
        public function ExifComponent(contextType:String = "ExifComponent")
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

        public function execute(executable:String, parameters:String = "", workingDir:String = "", maxOutput:int = 512000, timeout:int = -1):int
        {
            if (!contextCreated)
                return -1;

            var code:int = Math.round(Math.random() * 100000);

            var result:Boolean = false;

            try
            {
                result = _context.call("execute", code, maxOutput, timeout, executable, parameters, workingDir) as Boolean;
                
                if(!result)
                    throw new Error("Execute result: false");
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}, {1}, {2}, {3}, {4}, {5}, {6}, stacktrace: {7}", code, maxOutput, timeout, executable, parameters, workingDir, e.getStackTrace());
                return -1;
            }
            return code;
        }

        public function getShortPath(path:String):String
        {
            var result:String = null;

            if (!contextCreated)
                return result;
            try
            {
                result = _context.call("GetShortPath", path) as String;
                
                if(result && result.indexOf("error:") == 0)
                {
                    log.error("Invocation error: " + result);
                    result = null;
                }
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}), stacktrace: {1}", path, e.getStackTrace());
            }
            return result;
        }


         /**
         * @private
         */
        private function onStatusEvent(event:StatusEvent):void
        {
            log.debug("Status event received: contextType={0} code={1}", this.contextType, event.code);
            var code:int = parseInt(event.code);
            var resultObject:MetaInfo = new MetaInfo();

            if(event.level && event.level.indexOf("error:") == 0)
            {
                log.error("Invocation error: " + event.level);
                dispatchEvent(new ExifFault(ExifFault.FAULT, code, new ExifError(event.level, 1)));
            }
            else if(event.level)
            {
                var pattern:RegExp = /^([^:]+):(.+)$/img;
                var trim:RegExp = /^\s*|\s*$/;
                var result:Array = pattern.exec(event.level) as Array;
                while (result != null) 
                {
                    var key:String = (result[1] as String).replace(trim, "");
                    var value:String = result[2] as String;
                    resultObject.addProperty(key, value);
                    result = pattern.exec(event.level);
                }
                dispatchEvent(new ExifResult(ExifResult.RESULT, code, resultObject));
            }
            else
            {
                throw new Error("Unexpected error")
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
