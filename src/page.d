import std.xml;
import std.json;
import std.conv;
import std.stdio;
import std.file;

string stylesheet = ".tile {width: 200px; height: 300px;}";

string mano() {
	string[] ids = to!(string[])(parseJSON(readText("/mnt/satis/films/popular.json")).array());
	writeln(ids);

	auto document = new Document(new Tag("html"));
	document.prolog = "<!DOCTYPE html>";
	
	auto head = new Element("head");
	auto style = new Element("style");
	style ~= new Text(stylesheet);
	head ~= style;
	auto title = new Element("title");
	title ~= new Text("Mano");
	head ~= title;
	
	auto bod = new Element("body");
	bod ~= new Text("hoi");
	
	// names
	foreach (id; ids) {
		auto film = new Element("img");
		film.tag.attr["class"] = "tile";
		film.tag.attr["src"] = "/video/" ~ id[1..$-1] ~ "/poster.jpg";
		bod ~= film;
	}
	document ~= head;
	document ~= bod;
	
	return document.toString();	
}
