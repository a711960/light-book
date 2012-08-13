package light.book.lucene
{
    /**
     * Specifies whether and how a field should be indexed.
     */
    public class Store
    {
        /**
         * Store the original field value in the index.
         * This is useful for short texts like a document's title which should be displayed with the results.
         * The value is stored in its original form, i.e. no analyzer is used before it is stored.
         */
        public static const STORE_YES:int = 1;

        /**
         *     Do not store the field value in the index.
         */
        public static const STORE_NO:int = 2;

        /**
         * Store the original field value in the index in a compressed form.
         * This is useful for long documents and for binary valued fields.
         * NOTE: CLucene does not directly support compressed fields, to store a compressed field.
         * //TODO: need better documentation on how to add a compressed field
         * //because actually we still need to write a GZipOutputStream...
         */
        public static const STORE_COMPRESS:int = 4;
    }
}
