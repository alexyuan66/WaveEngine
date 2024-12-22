import std.string;
import std.conv;
import std.stdio;
import std.exception;

import bindbc.sdl;
import sdl_abstraction;

/**
 * Load and store game behavior parameters.
 */
struct ConfigManager{
    /**
     * Reset to the default parameters when destroyed.
     */
    ~this()
    {
        mGravity = 0.7;
        mCellSize = 28;
        mPlayerSpeed = 4;
        mSpriteMap.clear();

    }

    /**
     * Return a static instance of ConfigManager for global use.
     *
     * @return the global ConfigManager.
     */
    static ConfigManager* GetInstance()
    {
        if (mInstance is null)
        {
            mInstance = new ConfigManager();
        }
        return mInstance;
    }

    /**
     * Reset the global ConfigManager instance.
     *
     * This resets the parameters.
     * @see ::~this
     */
    static void ClearInstance(){
        mInstance = null;
    }

    /**
     * Set a new gravity value.
     *
     * @param gravity the new gravity value in pixels/frame^2.
     */
    static void SetGravity(float gravity)
    {
        mGravity = gravity;
    }

    /**
     * Get the current gravity value.
     *
     * @return the gravity value in pixels/frame^2.
     */
    static float LoadGravity()
    {
        return mGravity;
    }

    /**
     * Set a new size for each grid cell.
     *
     * @param cellSize the new width and height of each cell.
     */
    static void SetCellSize(int cellSize)
    {
        mCellSize = cellSize;
    }

    /**
     * Get the current size for each grid cell.
     *
     * @return the width and height of each cell.
     */
    static int LoadCellSize()
    {
        return mCellSize;
    }

    /**
     * Set a new speed for the player.
     *
     * @param playerSpeed the new speed in pixels/frame.
     */
    static void SetPlayerSpeed(int playerSpeed)
    {
        mPlayerSpeed = playerSpeed;
    }

    /**
     * Get the current speed for the player.
     *
     * @return the player speed in pixels/frame.
     */
    static int LoadPlayerSpeed()
    {
        return mPlayerSpeed;
    }

    /**
     * Set a new sprite file path for the player.
     *
     * @param sprite the name of the sprite to update.
     * @param path the new file path.
     */
    static void SetSpritePath(string sprite, string path)
    {
        mSpriteMap[sprite] = path;
    }

    /**
     * Get the current sprite file path for the player.
     *
     * @return the player's sprite file path.
     */
    static string LoadSpritePath(string sprite)
    {
        return mSpriteMap[sprite];
    }

    /**
     * Set a new bounce height.
     *
     * @param bounceHeight the new bounce height.
     */
    static void SetBounceHeight(float bounceHeight)
    {
        mBounceHeight = bounceHeight;
    }

    /**
     * Get the current bounce height.
     *
     * @return the bounce height.
     */
    static float LoadBounceHeight()
    {
        return mBounceHeight;
    }

private:
    static ConfigManager* mInstance;
    static float mGravity;
    static int mCellSize;
    static int mPlayerSpeed;
    static float mBounceHeight;
    static string[string] mSpriteMap;
}
