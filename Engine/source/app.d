/// Run with: 'dub'
import std.stdio;
import core.stdc.stdlib;
import gameapplication;

// Entry point to program
void main(string[] args)
{
	GameApplication app = GameApplication("Frames Per Second: 0", 60);
	app.RunLoop();
}