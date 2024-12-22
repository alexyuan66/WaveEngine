import std.string;
import std.conv;
import std.stdio;
import std.exception;
import std.random;
import std.datetime;

import audio;

import bindbc.sdl;
import sdl_abstraction;

/**
 * Handle all loading of assets.
 **/
struct ResourceManager{
    /**
     * Destroy assets stored in memory when the ResourceManager is destroyed.
     */
    ~this()
    {
        foreach (filename, texture; mImageResourceMap) 
        {
            SDL_DestroyTexture(texture);
        }
        mImageResourceMap.clear();

        foreach (fontkey, font; mFontResourceMap)
        {
            TTF_CloseFont(font);
        }
        mFontResourceMap.clear();
    }

    /**
     * Return a static instance of ResourceManager for global use.
     *
     * @return the global ResourceManager.
     */
    static ResourceManager* GetInstance()
    {
        if (mInstance is null)
        {
            mInstance = new ResourceManager();
            rng = Random(cast(uint) Clock.currTime().toUnixTime);
        }
        return mInstance;
    }

    /**
     * Load an image texture from a file path.
     *
     * @param renderer the SDL renderer.
     * @param filename the file path to the `.bmp` file.
     *
     * @return a loaded SDL texture pointer.
     */
    static SDL_Texture* LoadTexture(SDL_Renderer* renderer, string filename)
    {
        if (filename in mImageResourceMap)
        {
            return mImageResourceMap[filename];
        }
        else
        {
            SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
            SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
            SDL_FreeSurface(surface);
            mImageResourceMap[filename] = texture;
            return texture;
        }
    }

    /**
     * Load a font from a file path.
     *
     * @param fontPath the file path to the `.ttf` file.
     * @param fontSize the font size to load.
     *
     * @return a loaded SDL font pointer.
     */
    static TTF_Font* LoadFont(string fontPath, int fontSize)
    {
        string fontKey = fontPath ~ to!string(fontSize);
        if (fontKey in mFontResourceMap)
        {
            return mFontResourceMap[fontKey];
        }
        TTF_Font* font = TTF_OpenFont(fontPath.toStringz, fontSize);

        mFontResourceMap[fontKey] = font;
        return font;
    }

    /**
     * Load a randomness generator.
     *
     * @return the randomness generator.
     */
    static ref Random GetRNG()
    {
        return rng;
    }

private:
    static ResourceManager* mInstance;
    static SDL_Texture*[string] mImageResourceMap;
    static TTF_Font*[string] mFontResourceMap;
    static Random rng;
}
