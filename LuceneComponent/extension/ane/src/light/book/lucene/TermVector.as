package light.book.lucene
{
    /**
     * Specifies whether and how a field should have term vectors.
     */
    public class TermVector
    {
        /**
         * Do not store term vectors.
         */
        public static const TERMVECTOR_NO:int = 256;

        /**
         * Store the term vectors of each document.
         * A term vector is a list of the document's terms and their number of occurrences in that document.
         */
        public static const TERMVECTOR_YES:int = 512;

        /**
         * Store the term vector + token position information.
         */
        public static const TERMVECTOR_WITH_POSITIONS:int = TERMVECTOR_YES | 1024;

        /**
         * Store the term vector + Token offset information.
         */
        public static const TERMVECTOR_WITH_OFFSETS:int = TERMVECTOR_YES | 2048;

        /**
         * Store the term vector + Token position and offset information.
         */
        public static const TERMVECTOR_WITH_POSITIONS_OFFSETS:int = TERMVECTOR_WITH_OFFSETS | TERMVECTOR_WITH_POSITIONS;

    }
}
