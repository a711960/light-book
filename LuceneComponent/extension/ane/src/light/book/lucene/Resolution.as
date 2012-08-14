package light.book.lucene
{
    public class Resolution
    {
        /**
         * Use empty string
         */
        public static const NO_RESOLUTION:int = 0;

        /**
         * "YYYY"
         */
        public static const YEAR_FORMAT:int = 1;

        /**
         * "YYYYMM"
         */
        public static const MONTH_FORMAT:int = 2;

        /**
         * "YYYYMMDD"
         */
        public static const DAY_FORMAT:int = 3;

        /**
         * "YYYYMMDDHH"
         */
        public static const HOUR_FORMAT:int = 4;

        /**
         * "YYYYMMDDHHNN"
         */
        public static const MINUTE_FORMAT:int = 5;

        /**
         * "YYYYMMDDHHNNSS"
         */
        public static const SECOND_FORMAT:int = 6;

        /**
         * "YYYYMMDDHHNNSSQQQQ"
         */
        public static const MILLISECOND_FORMAT:int = 7;

    }
}
