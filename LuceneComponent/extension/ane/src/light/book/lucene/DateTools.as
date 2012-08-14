package light.book.lucene
{
    import mx.formatters.DateFormatter;

    public class DateTools
    {
        private static const formatter:DateFormatter = new DateFormatter();
        private static const MILLISECOND_FORMAT:String = "YYYYMMDDHHNNSSQQQQ";
        private static const SECOND_FORMAT:String = "YYYYMMDDHHNNSS";
        private static const MINUTE_FORMAT:String = "YYYYMMDDHHNN";
        private static const YEAR_FORMAT:String = "YYYY";
        private static const MONTH_FORMAT:String = "YYYYMM";
        private static const DAY_FORMAT:String = "YYYYMMDD";
        private static const HOUR_FORMAT:String = "YYYYMMDDHH";

        public static function dateToString(date:Date, resolution:int = Resolution.MILLISECOND_FORMAT):String
        {
            var format:String = "";
            if (resolution == Resolution.MILLISECOND_FORMAT)
            {
                format = MILLISECOND_FORMAT;
            }
            else if (resolution == Resolution.SECOND_FORMAT)
            {
                format = SECOND_FORMAT;
            }
            else if (resolution == Resolution.MINUTE_FORMAT)
            {
                format = MINUTE_FORMAT;
            }
            else if (resolution == Resolution.YEAR_FORMAT)
            {
                format = YEAR_FORMAT;
            }
            else if (resolution == Resolution.MONTH_FORMAT)
            {
                format = MONTH_FORMAT;
            }
            else if (resolution == Resolution.DAY_FORMAT)
            {
                format = DAY_FORMAT;
            }
            else if (resolution == Resolution.HOUR_FORMAT)
            {
                format = HOUR_FORMAT;
            }

            formatter.formatString = format;
            return formatter.format(date);
        }
    }
}
