import std.socket;
import std.datetime;
import bittorrent, bencode;
import std.format;
import std.conv;
import std.array;
import std.string;
import std.stdio;

struct TrConnReq {
	ulong connection;
	uint action;
	uint transaction;
}

struct TrConnResp {
	uint action;
	uint transaction;
	ulong connection;
}

struct TrAnnReq {
	TrConnReq conn;
	ubyte[20] infohash;
	ubyte[20] peerid;
	ulong downloaded;
	ulong left;
	ulong uploaded;
	uint event;
	uint ipv4;
	uint key;
	uint numwant;
	ushort port;
}

struct Peer {
	uint ipv4;
	ushort port;
}

struct TrAnnResp {
	uint action;
	uint transaction;
	uint interval;
	uint leechers;
	uint seeders;
	Peer[] peers;
}
	

uint htonl(uint val) {
	return
		  ((val & 0xFF000000) >> 24)
		| ((val & 0x00FF0000) >> 8)
		| ((val & 0x0000FF00) << 8)
		| ((val & 0x000000FF) << 24);
}

ulong htonl(ulong val) {
	return
		  ((val & 0xFF00000000000000) >> 56)
		| ((val & 0x00FF000000000000) >> 40)
		| ((val & 0x0000FF0000000000) >> 24)
		| ((val & 0x000000FF00000000) >> 8)
		| ((val & 0x00000000FF000000) << 8)
		| ((val & 0x0000000000FF0000) << 24)
		| ((val & 0x000000000000FF00) << 40)
		| ((val & 0x00000000000000FF) << 56);
}

class Tracker {
	UdpSocket socket;
	Address address;
	SysTime valid;
	string uri;
	ulong connection;
	
	this (string uri) {
		this.uri = uri;
		string domain, port;
		formattedRead(uri, "udp://%s:%s", &domain, &port);
		if (port.indexOf('/') > 0)
			port = port.split('/')[0];
		writeln(domain ~ port);
		auto infos = getAddress(domain, to!ushort(port));
		address = infos[0];
		socket = new UdpSocket;
		socket.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, dur!"seconds"(4));
		socket.connect(address);
	}
	
	void ensureConnected() {
		if (valid < Clock.currTime())
			connect();
	}
	
	void connect() {
		TrConnReq req;
		TrConnResp resp;
		
		req.connection = htonl(0x41727101980L);
		req.action = htonl(0);
		req.transaction = htonl(0x12AC3411);
		socket.send((&req)[0..1]);
		
		auto amount = socket.receive((&resp)[0..1]);
		resp.action = htonl(resp.action);
		resp.connection = htonl(resp.connection);
		resp.transaction = htonl(resp.transaction);
		
		connection = resp.connection;
		
		valid = Clock.currTime() + dur!"seconds"(120);
		
		if (resp.action != 0)
			throw new Exception("nooo");
	}
	
	Address[] announce(Torrent tor, Bittorrent bt) {
		ensureConnected();
		
		// send request
		TrAnnReq req;
		
		req.conn.connection = this.connection;
		req.conn.action = 1; // anounce
		req.conn.transaction = 0xDEAD;

		req.infohash = tor.metadata.infohash.data;
		//req.peerid = bt.self.data;
		req.downloaded = tor.downloaded;
		req.left = tor.left;
		req.uploaded = tor.uploaded;
		req.numwant = -1;
		req.port = 0;
		
		socket.send((&req)[0..1]);
		
		// get response hopefully
		TrAnnResp resp;
		
		auto len = socket.receive((&req)[0..1]);
		auto numpeers = (len - req.sizeof) / Peer.sizeof - 1;
		return [];
	}
		
	
	//Peer[] announce() {
	//	ensureConnected();
	//}
		
}
