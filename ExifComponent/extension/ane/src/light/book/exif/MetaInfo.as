package light.book.exif
{
    import flash.utils.Dictionary;

    public class MetaInfo
    {
        private var _info:Dictionary = new Dictionary();
        private var _keys:Array = [];
        private var _values:Array = [];
        
        public function MetaInfo()
        {
        }

        public function addProperty(key:String, value:String):void
        {
            _info[key] = value;
            _keys.push(key);
            _values.push(value);
        }

        public function getProperty(key:String):String
        {
            return _info[key];
        }

        public function get info():Dictionary
        {
            return _info;
        }

        public function get keys():Array
        {
            return _keys;
        }

        public function get values():Array
        {
            return _values;
        }

        public function get count():int
        {
            return _keys.length;
        }
    }
}
