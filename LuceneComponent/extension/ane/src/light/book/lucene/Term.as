package light.book.lucene
{
    public class Term
    {
        public var name:String;
        public var text:String;

        public function Term(name:String = null, text:String = null)
        {
            this.name = name;
            this.text = text;
        }

        public function toString():String
        {
            return "Term{name=" + String(name) + ",text=" + String(text) + "}";
        }
    }
}
