// @file: full_component/component.d
import std.stdio;
import std.math;
import std.algorithm;
import std.string;
import std.conv;
import std.json;
import std.random;
import std.datetime;

import bindbc.sdl;
import resourcemanager;

/**
 * The type of a given IComponent.
 */
enum ComponentType {
    TRANSFORM,      /**< Control where on screen the GameObject appears. */
    RENDER,         /**< Display an image on screen. */
    ANIMATION,      /**< Cycle through a sprite animation. */
    TEXT_RENDER,    /**< Display text on screen. */
    ATTEMPT         /**< Display the attempt number on screen. */
}

/**
 * Control a given component of a GameObject.
 *
 * @see GameObject
 */
interface IComponent
{
    /**
     * Update internal state of the component.
     */
    void Update();

    /**
     * Render the given component.
     */
    void Render(SDL_Renderer* renderer, SDL_Rect* camera);
}

/**
 * Store an individual frame for an animation.
 *
 * @see ComponentAnimation
 */
class Frame
{
    SDL_Rect mRect;

    this(SDL_Rect rect)
    {
        mRect = rect;
    }
}

/**
 * Contains the coordinates of the `GameObject`.
 *
 * Updating #x and #y instance variables will move the GameObject's rendered position.
 * @see IComponent
 * @see GameObject
 */
class ComponentTransform : IComponent
{
    int x;                  /**< X position of the GameObject in pixels (`0` is the left side of the screen). */
    int y;                  /**< Y position of the GameObject in pixels (`0` is the top of the screen). */
    int width;              /**< Width of the GameObject in pixels. */
    int height;             /**< Height of the GameObject in pixels. */
    float rotationAngle;    /**< Rotation angle in degrees. */
    private const float rotationSpeed = 360.0f / 90.0f; // Rotate fully every 90 frames
    SDL_Point mRotationCenter;  /**< The point about which to rotate. */
    private bool isSmall;

    /**
     * Initialize the GameObject's position
     *
     * @param owner the id of the attached GameObject.
     * @param x the initial x coordinate.
     * @param y the initial y coordinate.
     * @param width the width of the GameObject.
     * @param height the height of the GameObject.
     */
    this(size_t owner, int x, int y, int width, int height)
    {
        mOwner = owner;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.rotationAngle = 0.0f;
        this.isSmall = false;
        this.mRotationCenter = SDL_Point(width / 2, height / 2);
    }

    /**
     * Get an `SDL_Rect` representation of #x, #y, #width, and #height.
     *
     * @return An `SDL_Rect` of the GameObject's position.
     */
    SDL_Rect rect() {
        return SDL_Rect(x, y, width, height);
    }

    override void Update(){}

    override void Render(SDL_Renderer* renderer, SDL_Rect* camera){}

    /**
     * Checks whether the GameObject is visible to the camera.
     *
     * @return `true` if visible, otherwise `false`.
     */
    bool IsVisible(const SDL_Rect* camera) {
        SDL_Rect intersection;
        SDL_Rect r = rect();
        return SDL_IntersectRect(&r, camera, &intersection) == SDL_TRUE;
    }

    /**
     * Sets a new rotation angle for the GameObject.
     *
     * @param float the new angle value in degrees.
     * @see #rotationAngle
     * @see IncrementRotation
     */
    void SetRotationAngle(float angle)
    {
        rotationAngle = angle;
    }

    /**
     * Updates the rotation angle of the GameObject by an amount.
     *
     * @param delta the angle change amount in degrees.
     * @see #rotationAngle
     * @see SetRotationAngle
     */
    void IncrementRotation(float delta)
    {
        rotationAngle += delta;
        if (rotationAngle >= 360.0f) rotationAngle -= 360.0f;
    }

    /**
     * Sets whether the GameObject should render small or not.
     *
     * @param small `true` to render small, `false` to render normal sized.
     * @param isGravityFlipped whether gravity is flipped for the GameObject.
     *
     * @see #isSmall
     * @see GetSmall
     */
    void SetSmall(bool small, bool isGravityFlipped) {
        isSmall = small;
        if (small) {
            width = width / 2;
            height = height / 2;
            if (!isGravityFlipped)
            {
                y = y - height;
            }
            else
            {
                y = y + height;
            }
        } else {
            width = width * 2;
            height = height * 2;
            if (!isGravityFlipped)
            {
                y = y - height / 2;
            }
            else
            {
                y = y + height / 2;
            }
        }
        this.mRotationCenter = SDL_Point(width / 2, height / 2);
    }

    /**
     * Whether the GameObject is rendered small or not.
     *
     * @return `true` if rendering small, `false` if rendering normal sized.
     * @see #isSmall
     * @see SetSmall
     */
    bool GetSmall() {
        return isSmall;
    }

    private:
    size_t mOwner;
}

/**
 * Render the GameObject on screen using a BMP image file.
 *
 * The render location is defined by ComponentTransform.
 * The frame to render in an animation is defined by ComponentAnimation.
 * @see ComponentTransform
 * @see ComponentAnimation
 */
class ComponentRender : IComponent
{
    ComponentTransform mTransform;  /**< Stores the location and orientation in which to render the GameObject. */
    ComponentAnimation mAnimation;  /**< Stores the sprite details including which frame to render. */

    /**
     * Setup the renderer.
     *
     * @param owner the id of the attached GameObject.
     * @param renderer the SDL renderer object.
     * @param transform the ComponentTransform of the attached GameObject.
     * @param animation the ComponentAnimation of the attached GameObject.
     */
    this(size_t owner, SDL_Renderer* renderer, ComponentTransform transform, ComponentAnimation animation)
    {
        mOwner = owner;
        mTransform = transform;
        mAnimation = animation;
    }

    /**
     * Update the animation to go the next frame.
     */
    override void Update()
    {
        mAnimation.Update();
    }

    /**
     * Render the sprite on screen.
     *
     * @param renderer the SDL renderer to use.
     * @param camera the `SDL_Rect` corresponding to the camera position and size.
     */
    override void Render(SDL_Renderer* renderer, SDL_Rect* camera)
    {
        SDL_Rect result;

        result.x = cast(int)(mTransform.x - camera.x);
        result.y = cast(int)(mTransform.y - camera.y);
        result.w = cast(int)mTransform.width;
        result.h = cast(int)mTransform.height;

        SDL_Rect sourceRect = mAnimation.getCurrentFrameRect();
        SDL_Texture* texture = mAnimation.getSpritesheet();
        SDL_RenderCopyEx(renderer, texture, &sourceRect, &result, mTransform.rotationAngle, &mTransform.mRotationCenter, SDL_FLIP_NONE);
    }

    private:
    size_t mOwner;
}

/**
 * Chose the correct animation frame to display.
 *
 * The rendering is done by ComponentRender.
 * @see ComponentRender
 */
class ComponentAnimation : IComponent {
    SDL_Texture* mSpritesheet;  /**< The loaded SDL texture of the spritesheet. */
    Frame[] mFrames;            /**< A list of Frame objects in the animation. */
    int mCurrentFrame;          /**< The index of the current frame. */
    uint mLastFrameTime;        /**< The time when the last frame was rendered. */
    Random rng;                 /**< A random generator. */

    /**
     * Setup the renderer.
     *
     * @param owner the id of the attached GameObject.
     * @param renderer the SDL renderer object.
     * @param jsonPath the JSON file defining the sprite animation parameters.
     */
    this(size_t owner, SDL_Renderer* renderer, string jsonPath)
    {
        mOwner = owner;
        mLastFrameTime = SDL_GetTicks();
        Load(renderer, jsonPath);
    }

    /**
     * Update the current frame in the animation if enough time has passed.
     *
     * @see #mCurrentFrame
     * @see #mLastFrameTime
     */
    override void Update()
    {
        if (SDL_GetTicks() - mLastFrameTime > 150)
        {
            mCurrentFrame = (mCurrentFrame + 1) % cast(int)(mFrames.length);
            mLastFrameTime = SDL_GetTicks();
        }
    }

    override void Render(SDL_Renderer* renderer, SDL_Rect* camera){}

    /**
     * Get the loaded spritesheet texture.
     *
     * @return The loaded `SDL_Texture*`.
     */
    SDL_Texture* getSpritesheet()
    {
        return mSpritesheet;
    }

    /**
     * Get the spritesheet region corresponding to the current frame.
     *
     * @return An `SDL_Rect` that maps to the loaded texture.
     */
    SDL_Rect getCurrentFrameRect()
    {
        return mFrames[mCurrentFrame].mRect;
    }

    /**
     * Load a texture from a `.bmp` file.
     *
     * @param renderer the SDL renderer object.
     * @param jsonPath the JSON file defining the sprite animation parameters.
     */
    void Load(SDL_Renderer* renderer, string jsonPath){
        File myFile = File(jsonPath, "r");
        auto jsonFileContents = myFile.byLine.joiner("\n");
        auto j = parseJSON(jsonFileContents);
        string spritesheetPath = j["filepath"].to!string.replace(`\`, "").replace(`"`, ""); // Remove backslashes
        mSpritesheet = ResourceManager.GetInstance().LoadTexture(renderer, spritesheetPath);
        auto format_data = j["format"];
        
        // Parse format data and generate frames.
        int width = cast(int) format_data["width"].integer;
        int height = cast(int) format_data["height"].integer;
        int tile_width = cast(int) format_data["tileWidth"].integer;
        int tile_height = cast(int) format_data["tileHeight"].integer;
        int num_tiles_per_width = width / tile_width;
        int num_tiles_per_height = height / tile_height;
        

        for (int row = 0; row < num_tiles_per_height; row++)
        {
            for (int col = 0; col < num_tiles_per_width; col++)
            {
                int curr_y = row * tile_height;
                int curr_x = col * tile_width;
                mFrames ~= new Frame(SDL_Rect(curr_x, curr_y, tile_width, tile_height));
            }
        }
        
        mCurrentFrame = cast(int) uniform(0, cast(int) mFrames.length, ResourceManager.GetInstance().GetRNG());
    }

    private:
    size_t mOwner;
}

/**
 * Render the GameObject on screen as a piece of text.
 *
 * The render location is defined by ComponentTransform.
 * @see ComponentTransform
 */
class ComponentTextRenderer : IComponent
{
    SDL_Renderer* mRenderer;    /**< The SDL renderer object. */
    TTF_Font* mFont;            /**< The SDL font to use. */
    SDL_Color mColor;           /**< The color in which to render the text. */
    SDL_Texture* mTexture;      /**< The texture for the background. */
    SDL_Rect mRect;             /**< Screen-space rectangle for rendering text. */
    string mText;               /**< The text to display. */

    /**
     * Setup the renderer.
     *
     * @param owner the id of the attached GameObject.
     * @param renderer the SDL renderer object.
     * @param fontPath path to a TTF file containing the font to use.
     * @param fontSize the font size to display.
     * @param color the color of the text.
     * @param x the horizontal pixel position to display the text.
     * @param y the vertical pixel position to display the text (`0` is the top).
     */
    this(size_t owner, SDL_Renderer* renderer, string fontPath, int fontSize, SDL_Color color, int x, int y)
    {
        mOwner = owner;
        mRenderer = renderer;
        mColor = color;
        mFont = ResourceManager.GetInstance().LoadFont(fontPath, fontSize);
        mRect.x = x;
        mRect.y = y;
        mTexture = null;
    }

    /**
     * Cleanup texture memory usage.
     */
    ~this()
    {
        if (mTexture != null)
        {
            SDL_DestroyTexture(mTexture);
        }
    }

    /**
     * Update the background texture.
     */
    override void Update()
    {
        if (mTexture != null)
        {
            SDL_DestroyTexture(mTexture);
        }

        SDL_Surface* surface = TTF_RenderText_Blended(mFont, mText.toStringz, mColor);
        mTexture = SDL_CreateTextureFromSurface(mRenderer, surface);
        SDL_FreeSurface(surface);
        SDL_QueryTexture(mTexture, null, null, &mRect.w, &mRect.h);
    }

    /**
     * Render the text on screen.
     *
     * @param renderer the SDL renderer to use.
     * @param camera the `SDL_Rect` corresponding to the camera position and size.
     */
    override void Render(SDL_Renderer* renderer, SDL_Rect* camera)
    {
        if (mTexture != null && IsVisible(camera))
        {
            SDL_Rect result;
            result.x = mRect.x - camera.x;
            result.y = mRect.y - camera.y;
            result.w = mRect.w;
            result.h = mRect.h;

            SDL_RenderCopy(renderer, mTexture, null, &result);
        }
    }

    /**
     * Checks whether the GameObject is visible to the camera.
     *
     * @return `true` if visible, otherwise `false`.
     */
    bool IsVisible(SDL_Rect* camera)
    {
        return mRect.x + mRect.w > camera.x &&
               mRect.x < camera.x + camera.w &&
               mRect.y + mRect.h > camera.y &&
               mRect.y < camera.y + camera.h;
    }

    /**
     * Update the text to be displayed.
     *
     * @param newText string to display on screen.
     */
    void SetText(string newText)
    {
        mText = newText;
    }

    private:
    size_t mOwner;
}

/**
 * Render a number of attempts on screen.
 *
 * The render itself is done using a ComponentTextRenderer.
 * @see ComponentTextRenderer
 */
class ComponentAttempt : IComponent {
    ComponentTextRenderer mTextRenderer;    /**< The ComponentTextRenderer of the attached GameObject. */
    int mAttempt = 1;                       /**< How many attempts have been made since opening the level. */

    /**
     * Setup the attempt counter.
     *
     * @param owner the id of the attached GameObject.
     * @param textRenderer the ComponentTextRenderer of the attached GameObject.
     */
    this(size_t owner, ComponentTextRenderer textRenderer)
    {
        mOwner = owner;
        mTextRenderer = textRenderer;
    }

    /**
     * Get the current attempt number.
     *
     * @return the current attempt number.
     */
    int getAttempt()
    {
        return this.mAttempt;
    }

    /**
     * Update the current attempt number.
     *
     * @param attempt the new attempt number.
     */
    void setAttempt(int attempt)
    {
        this.mAttempt = attempt;
    }

    /**
     * Update the text on screen to show the new attempt.
     */
    override void Update()
    {
        mTextRenderer.mText = "Attempt   "~mAttempt.to!string;
    }

    override void Render(SDL_Renderer* renderer, SDL_Rect* camera){}

    private:
    size_t mOwner;
}
