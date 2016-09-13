import std.net.curl;
import std.file, std.path;
import std.algorithm, std.conv, std.stdio;
import std.json;
import std.array;
import std.datetime;
import std.socket;
import std.path, std.json;
import core.thread;
import page;

struct Request {
	string[string] fields;
	string method;
	string path;
}

ubyte[] readRequest(Socket sock) {
	ubyte[] header;
	
	while (true) {
		ubyte[] buf = new ubyte[0x1000];
		long got = sock.receive(buf);
		writeln(got);
		header ~= buf[0..got];
		if (header[$-4 .. $] == [13,10,13,10])
			break;
	}
	return header;
}

Request parseRequest(ubyte[] request) {
	auto lines = request.split("\r\n");
	Request req;
	
	auto parts = lines[0].split(" ");
	req.method = cast(string)(parts[0]);
	req.path = cast(string)(parts[1]);
	
	foreach (line; lines[1..$]) {
		if (line.length == 0)
			break;
		auto kv = line.split(": ");
		req.fields[cast(string)(kv[0])] = cast(string)(kv[1]);
	}
	
	return req;
}

struct Response {
	string[string] fields;
	int code;
}

ubyte[] buildResponse(Response resp) {
	auto data = "HTTP/1.1 " ~ to!string(resp.code) ~ " Ok" ~ "\r\n";
	foreach (key,val; resp.fields)
		data ~= key ~ ": " ~ val ~ "\r\n";
	data ~= "\r\n";
	return cast(ubyte[])data;
}

Response fileResponse(string path) {
	Response resp;
	auto size = getSize(path);
	resp.code = 200;
	resp.fields["Content-Length"] = to!string(size);
	return resp;
}

Response bufferResponse(string path) {
	Response resp;
	auto size = path.length;
	resp.code = 200;
	resp.fields["Content-Length"] = to!string(size);
	return resp;
}

Response errorResponse(string message) {
	Response resp;
	auto size = message.length;
	resp.code = 400;
	resp.fields["Content-Length"] = to!string(size);
	return resp;
}

class Serve : Thread {
	Socket client;
	
	this (Socket client) {
		this.client = client;
		super(&run);
	}
	
	void run() {
		try {
			auto request = parseRequest(readRequest(client));
			auto path = "/mnt/satis" ~ request.path;
			
			if (request.path == "/") {
				auto page = mano();
				auto response = buildResponse(bufferResponse(page));
				client.send(response);
				client.send(page);
			}
			else if (!exists(path)) {
				auto error = "ERROR: FILE NOT FOUND";
				auto response = buildResponse(errorResponse(error));
				client.send(response);
				client.send(error);
				writeln("NOT FOUND " ~ path);
			}
			
			
		
			// now we put 'em together
			else if (baseName(request.path) == ".directory") {
				string[] files;
				foreach (string sub; dirEntries(path, SpanMode.shallow))
					files ~= sub;
					
				auto json = to!JSONValue(files);
				auto buffer = toJSON(&json);
				
				auto response = buildResponse(bufferResponse(buffer));
				client.send(response);
				client.send(buffer);
			} else {			
				auto response = buildResponse(fileResponse(path));
				client.send(response);
				client.send(read(path));
			}
		} catch (Exception e) {
			auto error = "INTERNAL ERROR";
			auto response = buildResponse(errorResponse(error));
			client.send(response);
			client.send(error);
			writeln(e);
		}
	}
}
		

void webserve() {
	auto server = new TcpSocket();
	server.bind(parseAddress("127.0.0.1", 10601));
	server.listen(999);
	
	while (true) {
		writeln("Waiting...");
		auto client = server.accept();
		writeln("accepted");
		new Serve(client).start();
	}
	
}
