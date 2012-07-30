package light.book.exif
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    import mx.logging.ILogger;
    import mx.logging.Log;

    /**
     * Exiftool was executed with errors
     */
    [Event(name="EXIF_RESULT", type="light.book.exif.ExifResult")]

    /**
     * Exiftool was successfully executed
     */
    [Event(name="EXIF_FAULT", type="light.book.exif.ExifFault")]

    /**
     * <p>ExifComponent extension, interface to Exiftool</p>
     *
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
         * @param contextType default value is "ExifComponent"
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


        public function execute(executable:String, filePaths:Array, parameters:String = "", workingDir:String = "", maxOutput:int = 512000, timeout:int = -1):int
        {
            if (!contextCreated)
                return -1;

            var code:int = Math.round(Math.random() * 100000);

            try
            {
                _context.call("execute", code, maxOutput, timeout, executable, parameters, workingDir, filePaths);
            }
            catch (e:Error)
            {
                log.error("Invocation error: execute({0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, stacktrace: {8}", code, maxOutput, timeout, executable, parameters, workingDir, filePaths, e.getStackTrace());
                return -1;
            }
            return code;
        }

        /**
         * Returns file short path (8.3) by long path,
         * file must exist
         * @param path long path to existing file
         * @return short path (8.3) or null on error
         */
        public function getShortPath(path:String):String
        {
            var result:String = null;

            if (!contextCreated)
                return result;
            try
            {
                result = _context.call("GetShortPath", path) as String;
                
                if(ExifError.isError(result))
                {
                    var exifError:ExifError = ExifError.parseError(result);
                    log.error(exifError.toString());
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

            var result:Array = [];

            if(ExifError.isError(event.level))
            {
                var exifError:ExifError = ExifError.parseError(event.level);
                log.error(exifError.toString());
                dispatchEvent(new ExifFault(ExifFault.FAULT, code, exifError));
            }
            else if(event.level)
            {
                var matches:Array = event.level.split("\r");
                var key:String;
                var meta:MetaInfo;

                for (var i:int = 0; i < matches.length; i++)
                {
                    key = matches[i] as String;
                    if(key == "FileNameOriginal")
                    {
                        meta = new MetaInfo();
                        result.push(meta);
                    }
                    meta.addProperty(key, matches[i + 1]);
                    i++;
                }
                log.debug("Status event parsed: contextType={0} code={1}", this.contextType, event.code);
                dispatchEvent(new ExifResult(ExifResult.RESULT, code, result));
            }
            else
            {
                dispatchEvent(new ExifFault(ExifFault.FAULT, code, ExifError.UNKNOWN));
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
