package light.book.exif
{
    /**
     * Provides basic information about script errors
     */
    public class ExifError extends Error
    {
        /**
         * @inheritDoc
         */
        public function ExifError(message:* = "",id:* = 0)
        {
            super(message, id)
        }


        public function toString():String
        {
            return "ExifError{errorID=" + String(this.errorID) + ", message=" + this.message + "}";
        }
    }
}
