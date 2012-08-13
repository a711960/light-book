package light.book.lucene
{
    public class Term
    {
        public var name:String;
        public var value:String;

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
