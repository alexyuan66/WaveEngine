module sdl_abstraction;

import std.stdio;
import std.string;
import std.conv;

import bindbc.sdl;
import bindbc.sdl.mixer;
import bindbc.sdl.ttf;
import loader = bindbc.loader.sharedlib;

shared static this()
{
    // Platform-specific loading logic
    version (Windows)
    {
        auto sdlStatus = loadSDL("SDL2.dll");
        auto sdlTTFStatus = loadSDLTTF("SDL2_ttf.dll");
        if (sdlStatus != sdlSupport || sdlTTFStatus != sdlTTFSupport)
        {
            writeln("Failed to load SDL or SDL_ttf. Please check the library paths.");
            return;
        }
    }
    else version (OSX)
    {
        auto sdlStatus = loadSDL();
        auto sdlTTFStatus = loadSDLTTF();
        if (sdlStatus != sdlSupport || sdlTTFStatus != sdlTTFSupport)
        {
            writeln("Failed to load SDL or SDL_ttf. Please check the library paths.");
            return;
        }
    }
    else version (linux)
    {
        auto sdlStatus = loadSDL();
        auto sdlTTFStatus = loadSDLTTF();
        if (sdlStatus != sdlSupport || sdlTTFStatus != sdlTTFSupport)
        {
            writeln("Failed to load SDL or SDL_ttf. Please check the library paths.");
            return;
        }
    }

    if (loadSDLMixer() != sdlMixerSupport)
    {
        writeln("Failed to load SDL_mixer");
        return;
    }

    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0)
    {
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }

    if (Mix_OpenAudio(44_100, MIX_DEFAULT_FORMAT, 2, 2048) == -1)
    {
        throw new Exception("Failed to initialize SDL_mixer: " ~ Mix_GetError().to!string);
    }

    // SDL_ttf initialization
    if (TTF_Init() != 0)
    {
        writeln("TTF_Init error: ", fromStringz(TTF_GetError()));
    }
}

shared static ~this()
{
    TTF_Quit();
    SDL_Quit();
}
