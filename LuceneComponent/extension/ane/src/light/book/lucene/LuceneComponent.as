package light.book.lucene
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    import mx.logging.ILogger;
    import mx.logging.Log;

    /**
     * Exiftool was executed with errors
     */
    [Event(name="EXIF_RESULT", type="light.book.lucene.ExifResult")]

    /**
     * Exiftool was successfully executed
     */
    [Event(name="EXIF_FAULT", type="light.book.lucene.ExifFault")]

    /**
     * <p>ExifComponent extension, interface to Exiftool</p>
     *
     */
    public class LuceneComponent extends EventDispatcher
    {
        /**
         * Extension id, must be specified in air-manifest.xml and extension.xml
         */
        public static const CONTEXT:String = "light.book.lucene.LuceneComponent";

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
        public function LuceneComponent(contextType:String = "ExifComponent")
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


        public function test():Boolean
        {
            if (!contextCreated)
                return -1;

            var result:Boolean = false;

            try
            {
                result = _context.call("test");
            }
            catch (e:Error)
            {
                log.error("Invocation error: test(), stacktrace: {0}", e.getStackTrace());
                return false;
            }
            return result;
        }


         /**
         * @private
         */
        private function onStatusEvent(event:StatusEvent):void
        {
            log.debug("Status event received: contextType={0} code={1}", this.contextType, event.code);
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
