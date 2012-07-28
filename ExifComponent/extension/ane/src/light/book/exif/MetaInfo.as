package light.book.exif
{
    import flash.utils.Dictionary;
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    public dynamic class MetaInfo extends Proxy
    {
        private static const builtin:Object = {info:true, keys:true, values:true, count:true};

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

        override flash_proxy function getProperty(name:*):*
        {
            if (builtin[name])
            {
                switch (name.toString())
                {
                    case 'count':
                        return this.count;
                    case 'values':
                        return this.values;
                    case 'keys':
                        return this.keys;
                    case 'info':
                        return this.info;
                }
            }
            return _info[name];
        }

        override flash_proxy function setProperty(name:*, value:*):void
        {
            if (builtin[name] == null)
            {
                _info[name] = value;
                _keys.push(name);
                _values.push(value);
            }
        }

        override flash_proxy function deleteProperty(name:*):Boolean
        {
            if (builtin[name] == null && _info.hasOwnProperty(name))
            {
                delete _info[name];

                var pos:int = -1;

                _keys = _keys.filter(function (element:*, index:int, arr:Array):Boolean
                {
                    pos = index;
                    return element != name;
                });

                _values = _values.filter(function (element:*, index:int, arr:Array):Boolean
                {
                    return pos != index;
                });
                return true;
            }
            return false;
        }

        override flash_proxy function nextNameIndex(index:int):int
        {
            if (index < _keys.length + 4)
            {
                return index + 1;
            }
            else
            {
                return 0;
            }
        }

        override flash_proxy function nextName(index:int):String
        {
            switch (index)
            {
                case 0:
                    return 'count';
                case 1:
                    return 'values';
                case 2:
                    return 'keys';
                case 3:
                    return 'info';
            }

            return keys[index - 4];
        }

        override flash_proxy function nextValue(index:int):*
        {
            switch (index)
            {
                case 0:
                    return this.count;
                case 1:
                    return this.values;
                case 2:
                    return this.keys;
                case 3:
                    return this.info;
            }

            return values[index - 4];
        }

        override flash_proxy function callProperty(methodName:*, ... args):*
        {
            return getProperty(methodName);
        }
    }
}
