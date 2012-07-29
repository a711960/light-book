package light.book.exif
{
    import flash.utils.Dictionary;

    public class MetaInfo
    {
        public static const AUTO_ADD:Object = {FileName:true, Directory:true, FileSize:true, FileModifyDate:true, FilePermissions:true, FileNameOriginal:true, MIMEType:true, FileType:true, MD5:true, Error:true, Warning:true};

        private var _info:Dictionary = new Dictionary();
        private var _keys:Array = [];
        private var _values:Array = [];

        private var _FileName:String;
        private var _Directory:String;
        private var _FileSize:String;
        private var _FileModifyDate:String;
        private var _FilePermissions:String;
        private var _FileNameOriginal:String;
        private var _MIMEType:String;
        private var _FileType:String;
        private var _MD5:String;
        private var _Error:String;
        private var _Warning:String;


        public function MetaInfo()
        {
        }

        public function addProperty(key:String, value:String):void
        {
            _info[key] = value;
            _keys.push(key);
            _values.push(value);
            if (AUTO_ADD[key])
            {
                this["_" + key] = value;
                if (key == "Error" && value == "Unknown file type")
                {
                    var index:int = _FileNameOriginal ? _FileNameOriginal.toLowerCase().lastIndexOf(".") : -1;
                    if (index >= 0)
                    {
                        if (index < _FileNameOriginal.length - 1)
                        {
                            var extension:String = _FileNameOriginal.toLowerCase().substr(index + 1);
                            var mimeType:String = MimeTypeMap.instance.getMimeType(extension);

                            _FileType = extension ? extension.toUpperCase() : null;
                            _MIMEType = mimeType;
                        }
                    }
                }
            }
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

        public function get FileName():String
        {
            return _FileName;
        }

        public function get Directory():String
        {
            return _Directory;
        }

        public function get FileSize():String
        {
            return _FileSize;
        }

        public function get FileModifyDate():String
        {
            return _FileModifyDate;
        }

        public function get FilePermissions():String
        {
            return _FilePermissions;
        }

        public function get FileNameOriginal():String
        {
            return _FileNameOriginal;
        }

        public function get MIMEType():String
        {
            return _MIMEType;
        }

        public function get FileType():String
        {
            return _FileType;
        }

        public function get MD5():String
        {
            return _MD5;
        }

        public function get isError():Boolean
        {
            return _Error != null;
        }

        public function get isWarning():Boolean
        {
            return _Warning != null;
        }

        public function get Error():String
        {
            return _Error;
        }

        public function get Warning():String
        {
            return _Warning;
        }
    }
}
