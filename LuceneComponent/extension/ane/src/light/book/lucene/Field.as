package light.book.lucene
{
    /**
     * A field is a section of a Document. Each field has two parts, a name and a value.
     * Values may be free text, provided as a String or as a Reader, or they may be atomic keywords,
     * which are not further processed.
     * Such keywords may be used to represent dates, urls, etc. Fields are optionally stored in the index,
     * so that they may be returned with hits on the document.
     */
    public class Field
    {
        /**
         * The name of the field.
         */
        public var name:String;

        /**
         * Specifies whether and how a field should be stored.
         */
        public var store:int;

        /**
         * Specifies whether and how a field should be indexed.
         */
        public var index:int;

        /**
         * The string to process.
         */
        public var value:String;

        /**
         * Specifies whether and how a field should have term vectors.
         */
        public var termVector:int;


        public function Field(name:String, value:String = null, store:int = Store.STORE_YES, index:int = Index.INDEX_TOKENIZED, termVector:int = TermVector.TERMVECTOR_YES)
        {
            this.name = name;
            this.value = value;
            this.store = store;
            this.index = index;
            this.termVector = termVector;
        }
    }
}