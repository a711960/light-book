package light.book.lucene
{
    /**
     * A Term represents a word from text.
     */
    public class Term
    {
        /**
         * The name of the field.
         */
        public var name:String;

        /**
         * The text of the new term (field is implicitly same as this Term instance).
         */
        public var value:String;

        /**
         * Constructor.
         */
        public function Term(name:String = null, value:String = null)
        {
            this.name = name;
            this.value = value;
        }

        public function toString():String
        {
            return "Term{name=" + String(name) + ",value=" + String(value) + "}";
        }
    }
}
