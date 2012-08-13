package light.book.lucene
{
    /**
     * Specifies whether and how a field should be indexed.
     */
    public class Index
    {
        /**
         * Do not index the field value.
         * This field can thus not be searched, but one can still access its contents provided it is stored.
         */
        public static const INDEX_NO:int = 16;

        /**
         * Index the field's value so it can be searched.
         * An Analyzer will be used to tokenize and possibly further normalize the text before its terms will be stored in the index.
         * This is useful for common text.
         */
        public static const INDEX_TOKENIZED:int = 32;


        /**
         * Index the field's value without using an Analyzer, so it can be searched.
         * As no analyzer is used the value will be stored as a single term. This is useful for unique Ids like product numbers.
         */
        public static const INDEX_UNTOKENIZED:int = 64;

        /**
         * Index the field's value without an Analyzer, and disable the storing of norms.
         * No norms means that index-time boosting and field length normalization will be disabled.
         * The benefit is less memory usage as norms take up one byte per indexed field for every document in the index.
         * Note that once you index a given field with norms enabled, disabling norms will have no effect.
         * In other words, for NO_NORMS to have the above described effect on a field,
         * all instances of that field must be indexed with NO_NORMS from the beginning.
         */
        public static const INDEX_NONORMS:int = 128;

    }
}
