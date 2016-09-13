import app;
import std.socket;
import std.array;
import std.stdio;
import std.uri;
import std.format;
import std.socket;
import std.datetime;
import std.container;
import std.conv;
import std.digest.sha;
import std.file;
import bencode;
import tracker;

int hexcharDecode(char ch) {
	if ('a' <= ch && ch <= 'f')
		return ch - 'a' + 10;
	if ('A' <= ch && ch <= 'F')
		return ch - 'A' + 10;
	if ('0' <= ch && ch <= '9')
		return ch - '0';
	return -1;
}

ubyte[] hexDecode(string hex) {
	ubyte[] output;
	for (int i = 0; i < hex.length; i+=2) {
		char a = hex[i+0];
		char b = hex[i+1];
		output ~= cast(byte)((hexcharDecode(a) << 4) | (hexcharDecode(b)));
		
	}
	return output;
}

class Peerid {
	ubyte[20] data;
}
		

class Infohash {
	ubyte[20] data;
	
	this (string hex) {
		if (hex[0..9] == "urn:btih:")
			hex = hex[9..$];
		data = hexDecode(hex);
		assert(data.length == 20);
	}
	
	this (BValue info) {
		data = sha1Of(encode(info));
	}		
}

class Magnet {
	string name;
	Infohash infohash;
	Tracker[] trackers;	
	
	this (string magnet) {
		assert(magnet[0..8] == "magnet:?");
		magnet = magnet[8..$];
		auto parts = magnet.split('&');
		foreach (part; parts) {
			auto kv = part.split('=');
			auto key = decodeComponent(kv[0]);
			auto val = decodeComponent(kv[1]);
			
			if (key == "tr") {
				try {
					trackers ~= new Tracker(val);
				} catch (Exception e) {
					// oh well
				}
			}
			else if (key == "xt")
				infohash = new Infohash(val);
			else if (key == "dn")
				name = val;
		}
	}
}

struct File {
	ulong size;
	string path;
}

class Hash {
	ubyte[] data;
	
	this (ubyte[] data) { this.data = data; }
}

class Metadata {
	Infohash infohash;
	File[] files;
	Hash[] hashes;
	ulong pieceLength;
	
	this (BValue info) {
		infohash = new Infohash(info);
		pieceLength = info["piece length"].integer;
		string name = info["name"].text;
		
		// hash
		auto bhashes = info["pieces"].text;
		for (int i = 0; i < bhashes.length; i+=20) {
			auto hash = bhashes[i..i+20];
			hashes ~= new Hash(cast(data)hash);
		}
		
		// MULTIFILE
		foreach (bfile; info["files"].list) {
			File file;
			file.size = bfile["length"].integer;
			file.path = name;
			foreach (sub; bfile["path"].list)
				if (sub.text.length > 0)
					file.path ~= "/"~sub.text;
			files ~= file;
		}
		
		// TODO SINGLEFILE
					
	}
}


class Torrent {
	string tempName;
	Tracker[] trackers;
	Peer[] peers;
	Infohash infohash;
	Metadata metadata; // can be null!
	
	// temp state
	bool paused;
	
	// stats
	uint downloaded;
	uint uploaded;
	uint left;

	this (Bittorrent bt, string hexhash) {
		auto ih = new Infohash(hexhash);
	}		
	
	this (Bittorrent bt, BValue tor) {
		metadata = new Metadata(tor["info"]);
		this.infohash = metadata.infohash;
		
		// trackers
		if ("announce" in tor.dict) try {
			trackers ~= bt.tracker(tor["announce"].text);
		} catch (Exception) { }
		if ("announce-list" in tor.dict) {
			foreach (tracker; tor["announce-list"].list) {
				try {
				trackers ~= bt.tracker(tracker[0].text);
				} catch (Exception) { }
			}
		}
	}
	
	this (Magnet magnet) {
		this.infohash = magnet.infohash;
		this.tempName = magnet.name;
		this.trackers = magnet.trackers;
	}
	
	// save ourselves!!
	BValue save() {
		auto root = new BValue(Type.dict);
		
		// trackers
		if (trackers.length > 0)
			root["announce"] = trackers[0].uri;
		if (trackers.length > 1) {
			root["announce-list"] = new BValue(Type.list);
			
			foreach (tracker; trackers) {
				auto one = new BValue(Type.list);
//				one ~= tracker.save();
			}
		}
		
		return root;
	}
				
		
	
	//int opCmp(Torrent other) {
	//	return priority < other.priority;
	//}
}

class Bittorrent {
	byte[20] self;
	Tracker[string] trackers;
	Torrent[Infohash] torrents;
	
	Tracker tracker(string url) {
		if (url !in trackers)
			trackers[url] = new Tracker(url);
		return trackers[url];
	}
	
	void save() {
		string path = "/var/cache/sas/torrent";
		mkdirRecurse(path);
		
		foreach (ih,tor; torrents) {
			//mkdirRecurse(path ~ ih);
		}
			
	}	
}

