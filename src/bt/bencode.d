import std.conv;
import std.array;
import std.ascii;
import std.algorithm;

alias data = ubyte[];
enum Type {integer, text, list, dict}

class BValue {
public:
	Type type;	
	
	union {
		ulong integer;
		string text;
		BValue[] list;
		BValue[string] dict;
	}
	
	this (Type type) { this.type = type; }
	
	string opCast(string)() {
		assert(type == Type.text);
		return text;
	}
	
	ulong opCast() {
		assert(type == Type.integer);
		return integer;
	}
	
	BValue opIndex(string txt) {
		assert(type == Type.dict);
		return dict[txt];
	}
	
	BValue opIndex(int i) {
		assert(type == Type.list);
		return list[i];
	}
	
	BValue opAssign(string text) {
		type = Type.text;
		this.text = text;
		return this;
	}
	
	BValue opAssign(int integer) {
		type = Type.integer;
		this.integer = integer;
		return this;
	}
	
	BValue opIndexAssign(BValue val, string key) {
		type = Type.dict;
		dict[key] = val;
		return this;
	}
	
	BValue opIndexAssign(string val, string key) {
		type = Type.dict;
		BValue bval = new BValue(Type.text);
		bval = val;
		dict[key] = bval;
		return this;
	}
	
	
	BValue opIndexAssign(BValue val, int key) {
		type = Type.integer;
		list[key] = val;
		return this;
	}
	
	/*BValue opOpAssign!('-')(BValue val) {
		type = Type.integer;
		list ~= val;
	}*/
}

ulong readInt(ref ubyte[] data) {
	ulong i;
	char prev;
	if (!isDigit(data.front))
		throw new Exception("no integer data");
	while (isDigit(data.front)) {
		prev = data.front;
			
		i = i * 10 + (data.front - '0');
		data = data[1..$];
		
		if (prev == '0' && data.front == '0' && data.length > 1)
			throw new Exception("leading zeroes");
	}
	return i;
}

BValue decodeText(ref ubyte[] data) {
	auto btext = new BValue(Type.text);
	auto length = readInt(data);
	assert(data.front == ':');
	data = data[1..$];
	btext.text = cast(string) data[0..length];
	data = data[length..$];
	return btext;
}

BValue decodeDict(ref ubyte[] data) {
	auto dict = new BValue(Type.dict);
	data = data[1..$];
	string lastkey;
	
	while (true) {
		if (data.front == 'e') {
			data = data[1..$];
			return dict;
		}
		auto key = decodeText(data);
		if (key.text < lastkey)
			throw new Exception("unordered keys");
		auto val = decode(data);
		if (key.text in dict.dict)
			throw new Exception("duplicate keys");
		dict.dict[key.text] = val; 
	}
}

BValue decodeList(ref ubyte[] data) {
	auto blist = new BValue(Type.list);
	assert(data.front == 'l');
	data = data[1..$];
	while (data.front != 'e')
		blist.list ~= decode(data);
	data = data[1..$];
	return blist;
}

BValue decodeInteger(ref ubyte[] data) {
	auto binteger = new BValue(Type.integer);
	assert(data.front == 'i');
	data = data[1..$];
	binteger.integer = readInt(data);
	assert(data.front == 'e');
	data = data[1..$];
	return binteger;
}

BValue decode(ref data data) {
	if (data.front == 'd')
		return decodeDict(data);
	else if (data.front == 'l')
		return decodeList(data);
	else if (data.front == 'i')
		return decodeInteger(data);
	else if (isDigit(data.front))
		return decodeText(data);
	else
		throw new Exception("unrecognized character " ~ data.front);
}

data encodeText(string text) {
	return cast (data) (to!string(text.length) ~ ':' ~ text);
}

data encode(BValue bvalue) {
	final switch (bvalue.type) {
		case Type.integer:
			return cast(ubyte[]) ('i' ~ to!string(bvalue.integer) ~ 'e');
		case Type.text:
			return encodeText(bvalue.text);
		case Type.list:
			ubyte[] data = ['l'];
			foreach (value; bvalue.list)
				data ~= encode(value);
			data ~= 'e';
			return data;
		case Type.dict:
			ubyte[] data = ['d'];
			string[] keys;
			
			// sorted keys!
			foreach (key,val ; bvalue.dict)
				keys ~= key;
				
			sort(keys);
			
			foreach (key; keys) {
				data ~= encodeText(key);
				data ~= encode(bvalue.dict[key]);
			}
			data ~= 'e';
			return data;
	}
}

unittest {
	import std.functional;
	import std.stdio;
	import std.file : read;
	
	alias pipe!(decode, encode) x;
	
	// integer
	auto bint = cast(data) "i328e";
	assert(bint == x(bint));
	
	auto nobint1 = cast(data) "i001e";
	//error(xfer(nobint1));
	
	auto nobint2 = cast(data) "ie";
	//error(xfer(nobint2));
	
	// text
	auto text1 = cast (data) "3:hoi";
	auto text2 = cast (data) "0:";
	assert(text1 == x(text1));
	assert(text2 == x(text2));
	
	// list
	auto list = cast (data) "l2:he2:hae";
	assert(list == x(list));
	
	// dictionary
	auto dict = cast (data) "d1:a3:hoie";
	assert(dict == x(dict));
	
	// huge torrent
	auto torrent = cast (data) read("spiderman.torrent");
	assert(torrent == x(torrent));
	
}
