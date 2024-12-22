import component;
import std.stdio;
import std.math;
import std.algorithm;
import std.string;
import std.conv;
import std.json;

import bindbc.sdl;
import bindbc.sdl.bind.sdlmouse;

import resourcemanager;
import gameobject;
import configmanager;

alias ClickCallback = void function();

/**
 * The type of a given ComponentScript.
 */
enum ScriptType{PLAYER_MOVEMENT, PLAYER_JUMP, COLLISION, MOUSE_CLICK, TEXT_MOUSE_CLICK, PARALLAX, BOUNCE_HEIGHT};

/**
 * Control a given component of a GameObject.
 *
 * @see GameObject
 */
abstract class ComponentScript : IComponent
{
    /**
     * Store the owner id
     */
    this(size_t id)
    {
        mID = id;
    }

    /**
     * Update internal state of the script.
     */
    abstract override void Update();

    /**
     * Render the given script.
     */
    override void Render(SDL_Renderer* renderer, SDL_Rect* camera) {}

    private:
    size_t mID;
}

/**
 * Move the player by a specified amount each frame.
 */
class ComponentPlayerMovement : ComponentScript
{
    /**
     * The ComponentTransform of the linked GameObject.
     */
    ComponentTransform mTransform;
    
    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param transform the ComponentTransform of the linked GameObject.
     */
    this(size_t owner, ComponentTransform transform)
    {
        super(owner);
        mTransform = transform;
    }

    /**
     * Move the player forward.
     *
     * @see GameObject::Update
     */
    override void Update()
    {
        mTransform.x = mTransform.x + ConfigManager.GetInstance().LoadPlayerSpeed();
    }
}

/**
 * Move the player by a specified amount each frame.
 *
 * The amount is different from the player speed to give a 3D effect.
 */
class ComponentParallaxScroll : ComponentScript
{
    /**
     * The ComponentTransform of the linked GameObject.
     */
    ComponentTransform mTransform;

    /**
     * The speed to move the parallaxed GameObject.
     */
    int mSpeed;

    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param depth the speed to move the parallaxed GameObject..
     * @param transform the ComponentTransform of the linked GameObject.
     */
    this(size_t owner, int depth, ComponentTransform transform) {
        super(owner);
        mTransform = transform;
        mSpeed = max(0, min(depth, 3));
    }

    /**
     * Move the object forward.
     *
     * @see GameObject::Update
     */
    override void Update()
    {
        mTransform.x = mTransform.x + mSpeed;
    }
}

/**
 * Cause the player GameObject to jump on certain inputs.
 */
class ComponentPlayerInputJump : ComponentScript
{
    /**
     * The ComponentTransform of the linked GameObject.
     */
    ComponentTransform mTransform;

    /**
     * The ComponentRender of the linked GameObject.
     */
    ComponentRender mRender;

    float jumpVelocity = 0.0;               /**< Initial velocity when the jump starts. */
    private const float smallGravity = 0.9; /**< The gravity value to use if the GameObject is small. */
    const float jumpStrength = -13.0;       /**< Initial jump velocity (negative for upward motion). */
    const float maxVelocity = 10.0;         /**< The maximum velocity reachable during a fall. */
    bool isGrounded = false;                /**< Whether the player is on the ground. */
    const int groundLevel = 480;            /**< The lowest possible ground level (the GameObject can never go below this). */
    const int ceilingLevel = 0;             /**< The height possible ceiling level (the GameObject can never go above this). */
    const float rotationSpeed = 5.0f;       /**< Degrees per frame while jumping. */
    bool isGravityFlipped = false;          /**< Whether gravity is flipped to be the opposite direction or not. */

    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param depth the speed to move the parallaxed GameObject..
     * @param transform the ComponentTransform of the linked GameObject.
     */
    this(size_t owner, ComponentTransform transform, ComponentRender render)
    {
        super(owner);
        mTransform = transform;
        mRender = render;
    }

    /**
     * Get the height that the GameObject will reach on the next frame.
     *
     * @return the upcoming y coordinate.
     *
     * @see ComponentCollision::CheckForFloorCollision
     */
    int PreviewNextHeight() {
        bool isSmall = mTransform.GetSmall();
        float currentGravity = isSmall ? smallGravity : ConfigManager.GetInstance().LoadGravity();
        return mTransform.y + cast(int)(jumpVelocity + (isGravityFlipped ? -currentGravity : currentGravity));
    }

    /**
     * Reset the state of the jump to not be grounded.
     *
     * Run this to enter a free-fall state.
     */
    void ResetGrounded() {
        isGrounded = false;
    }

    /**
     * Stop jumping and remain grounded at a given height.
     *
     * The GameObject will stop at landHeight as if it has landed on an object.
     *
     * @param landHeight the end height in pixels of the jump.
     */
    void StopJump(int landHeight)
    {
        mTransform.y = landHeight;
        isGrounded = true;
        jumpVelocity = 0.0;

        // Always end up on side of square
        float snappedRotation = round((mTransform.rotationAngle + 5.0f) / 90.0f) * 90.0f;
        mTransform.SetRotationAngle(snappedRotation);
    }

    /**
     * Move the GameObject to the next location based on the gravity motion.
     *
     * @see ComponentTransform
     */
    override void Update()
    {
        SDL_PumpEvents();
        const ubyte* state = SDL_GetKeyboardState(null);
        bool isSmall = mTransform.GetSmall();
        float currentGravity = isSmall ? smallGravity : ConfigManager.GetInstance().LoadGravity();

        if (mTransform.y == (isGravityFlipped ? ceilingLevel : groundLevel - mTransform.height)) {
            isGrounded = true;
        }

        // Jump logic
        if (isGrounded && state[SDL_SCANCODE_SPACE])
        {
            isGrounded = false;
            jumpVelocity = (isGravityFlipped ? -jumpStrength : jumpStrength); // Set initial upward velocity
        }

        // Apply gravity to velocity
        jumpVelocity = isGravityFlipped ? max(jumpVelocity - currentGravity,  - maxVelocity) : min(jumpVelocity + currentGravity, maxVelocity);

        // Update vertical position
        mTransform.y += cast(int)jumpVelocity;

        // Rotate during the jump
        if (!isGrounded)
        {
            mTransform.IncrementRotation((isGravityFlipped ? -rotationSpeed : rotationSpeed));
        }

        // Ensure smooth landing at ground level
        if (isGravityFlipped ? (mTransform.y <= ceilingLevel) : (mTransform.y >= groundLevel - mTransform.height))
        {
            StopJump(isGravityFlipped ? ceilingLevel : groundLevel - mTransform.height);
        }
    }
}

/**
 * Handle a mouse click on a texture-based GameObject.
 */
class ComponentTransformMouseClick : ComponentScript
{
    ComponentTransform mTransform;      /**< The ComponentTransform of the linked GameObject. */
    void delegate() mCallbackFunction;  /**< The callback to run when a click event occurs. */
    SDL_Rect* mCamera;                  /**< The current camera position and size. */

    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param callbackFunction the callback.
     * @param transform the ComponentTransform of the linked GameObject.
     * @param callbackFunction the current camera position and size.
     */
    this(size_t owner, void delegate() callbackFunction, ComponentTransform transform, SDL_Rect* camera)
    {
        super(owner);
        mTransform = transform;
        mCallbackFunction = callbackFunction;
        mCamera = camera;
    }

    override void Update() {}

    /**
     * Check for an in-bounds mouse click and run #callback if one was found.
     */
    void LeftMouseClick()
    {
        // Check for overlap
        int mouseX, mouseY;
        uint state = SDL_GetMouseState(&mouseX, &mouseY);
        int render_x = mTransform.x - mCamera.x;
        int render_y = mTransform.y - mCamera.y;
        bool overlap = render_x <= mouseX && mouseX <= render_x + mTransform.width
            && render_y <= mouseY && mouseY <= render_y + mTransform.height;

        if (overlap) {
            mCallbackFunction();
        }
    }
}

/**
 * Handle a mouse click on a text-based GameObject.
 */
class ComponentTextMouseClick : ComponentScript
{
    ComponentTextRenderer mTextRenderer;    /**< The ComponentTextRenderer of the linked GameObject. */
    void delegate() mCallbackFunction;      /**< The callback to run when a click event occurs. */
    SDL_Rect* mCamera;                      /**< The current camera position and size. */

    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param callbackFunction the callback.
     * @param textRenderer the ComponentTextRenderer of the linked GameObject.
     * @param callbackFunction the current camera position and size.
     */
    this(size_t owner, void delegate() callbackFunction, ComponentTextRenderer textRenderer, SDL_Rect* camera)
    {
        super(owner);
        mTextRenderer = textRenderer;
        mCallbackFunction = callbackFunction;
        mCamera = camera;
    }

    override void Update() {}

    /**
     * Check for an in-bounds mouse click and run #callback if one was found.
     */
    void LeftMouseClick()
    {
        // Check for Overlap
        int mouseX, mouseY;
        uint state = SDL_GetMouseState(&mouseX, &mouseY);
        int render_x = mTextRenderer.mRect.x - mCamera.x;
        int render_y = mTextRenderer.mRect.y - mCamera.y;
        bool overlap = render_x <= mouseX && mouseX <= render_x + mTextRenderer.mRect.w
            && render_y <= mouseY && mouseY <= render_y + mTextRenderer.mRect.h;

        if (overlap) {
            mCallbackFunction();
        }
    }
}

/**
 * Check for collisions with other GameObject entities.
 */
class ComponentCollision : ComponentScript {
    ComponentTransform mTransform;      /**< The ComponentTransform of the linked GameObject. */
    ComponentPlayerInputJump mJump;     /**< The ComponentPlayerInputJump of the linked GameObject. */
    bool* mIsActive;                    /**< A pointer to whether the linked GameObject is active. */

    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param transform the ComponentTransform of the linked GameObject.
     * @param jump the ComponentPlayerInputJump of the linked GameObject.
     * @param isActive a pointer to whether the linked GameObject is active.
     */
    this(size_t owner, ComponentTransform transform, ComponentPlayerInputJump jump, bool* isActive) {
        super(owner);
        mTransform = transform;
        mJump = jump;
        mIsActive = isActive;
    }

    override void Update() {}

    /**
     * Check whether a floor collision will happen on the next frame update.
     *
     * Check whether the current gravity, velocity, and position will result in a floor collision.
     * If so, adjust the gravity/velocity value to land perfectly on top of the floor object.
     *
     * @see GameApplication::Update
     * @see GameApplication::CheckForLanding
     * @see ComponentPlayerInputJump::PreviewNextHeight
     */
    void CheckForFloorCollision(GameObject other, const SDL_Rect* camera) {
        if (other.GetName() != "Square") return;

        ComponentTransform otherTransform = cast(ComponentTransform) other.GetComponent(ComponentType.TRANSFORM);

        // If the other object is off screen, don't bother checking
        if (!otherTransform.IsVisible(camera)) return;

        SDL_Rect selfRect = mTransform.rect;
        SDL_Rect otherRect = otherTransform.rect();
        SDL_Rect intersection;

        // First, check whether there is currently a collision and exit if so since this will not be a ground-related collision
        if (SDL_IntersectRect(&selfRect, &otherRect, &intersection) == SDL_TRUE)
            return;

        // Move down by the gravity component
        selfRect.y = mJump.PreviewNextHeight();

        if (SDL_IntersectRect(&selfRect, &otherRect, &intersection) != SDL_TRUE)
            return;

        mJump.StopJump(selfRect.y + (mJump.isGravityFlipped ?  intersection.h : -intersection.h));
    }

    /**
     * Check for collisions with other GameObject entities.
     *
     * If a collision is found, mark the player as inactive since they are now "dead."
     *
     * Note: this intentionally does not differentiate between floor and enemy collisions.
     * It is expected that ::CheckForFloorCollision has already been run.
     *
     * @see GameApplication::Update
     * @see GameApplication::UpdateCollisions
     */
    void HandleCollision(GameObject collidee, const SDL_Rect* camera) {
        ComponentTransform collideeTransform = cast(ComponentTransform) collidee.GetComponent(ComponentType.TRANSFORM);
        SDL_Rect selfRect = mTransform.rect;
        SDL_Rect[] collideeHitboxes; 

        // If the other object is off screen, don't bother checking
        if (!collideeTransform.IsVisible(camera)) return;

        switch (collidee.GetName()) {
            case "Square":
            case "GravityFlipper":
            case "SizeFlipper":
                collideeHitboxes ~= collideeTransform.rect();
                break;
            case "Triangle":
                auto rect = collideeTransform.rect();
                SDL_Rect lowerHitbox = SDL_Rect(rect.x + (rect.w / 16), rect.y + (rect.h * 7 / 8), rect.w * 7 / 8, rect.h / 8);
                SDL_Rect upperHitbox = SDL_Rect(rect.x + (rect.w * 7 / 16), rect.y, rect.w / 8, rect.h * 7 / 8);
                collideeHitboxes ~= rotateRect(lowerHitbox, collideeTransform.rotationAngle, rect);
                collideeHitboxes ~= rotateRect(upperHitbox, collideeTransform.rotationAngle, rect);
                break;
            case "Bouncer":
                auto rect = collideeTransform.rect();
                SDL_Rect bouncerHitbox = SDL_Rect(rect.x, rect.y + (rect.h * 3 / 4), rect.w, rect.h / 4);
                collideeHitboxes ~= rotateRect(bouncerHitbox, collideeTransform.rotationAngle, rect);
                break;
            default:
                break;

        }

        SDL_Rect intersection;
        foreach(hitbox; collideeHitboxes) {
            if (SDL_IntersectRect(&selfRect, &hitbox, &intersection) == SDL_TRUE) {
                switch (collidee.GetName()) {
                    case "Square":
                    case "Triangle":
                        *mIsActive = false;
                        break;
                    case "Bouncer":
                        auto bounceComponent = cast(ComponentBounce)(collidee.GetScript(ScriptType.BOUNCE_HEIGHT));
                        mJump.jumpVelocity = (mJump.isGravityFlipped ? -bounceComponent.GetBounceHeight() : bounceComponent.GetBounceHeight());
                        break;
                    case "GravityFlipper":
                        if (collidee.IsEnabled()) {
                            mJump.isGravityFlipped = !mJump.isGravityFlipped;
                            mJump.isGrounded = false;
                            collidee.SetEnabled(false);
                        }
                        break;
                    case "SizeFlipper":
                        if (collidee.IsEnabled()) {
                            mTransform.SetSmall(!mTransform.GetSmall(), mJump.isGravityFlipped);
                            collidee.SetEnabled(false);
                        }
                        break;
                    default:
                        break;
                }
                break;
            }
        }
    }

    /**
     * Rotate a hitbox rectangle based on the rotation angle of the GameObject.
     *
     * @param rect the original position.
     * @param angle the angle to rotate by (either `90`, `180`, `270`, or `0`).
     * @param box the rotation point.
     */
    SDL_Rect rotateRect(SDL_Rect rect, float angle, SDL_Rect box)
    {
        SDL_Rect rotatedRect;
        int boxX = box.x;
        int boxY = box.y;
        int boxW = box.w; // Should always be 48
        int boxH = box.h; // Should always be 48

        switch (cast(int) angle)
        {
        case 90:
            rotatedRect = SDL_Rect(
                boxX + boxH - (rect.y - boxY + rect.h), // New x
                box.y + (rect.x - box.x),
                rect.h,
                rect.w
            );
            break;
        case 180:
            rotatedRect = SDL_Rect(
                boxX + boxW - (rect.x - boxX + rect.w),
                boxY + boxH - (rect.y - boxY + rect.h),
                rect.w,
                rect.h
            );
            break;
        case 270:
            rotatedRect = SDL_Rect(
                boxX + (rect.y - boxY),
                boxY + boxW - (rect.x - boxX + rect.w),
                rect.h,
                rect.w
            );
            break;
        default: // angle == 0
            rotatedRect = rect; // No rotation
        }

        return rotatedRect;
    }
}

/**
 * Make the component bounce.
 */
class ComponentBounce : ComponentScript
{
    /**
     * The bounce height in pixels
     */
    float bounceHeight;

    /**
     * Set up the script.
     *
     * @param owner the id of the linked GameObject.
     * @param bounceHeight the bounce height in pixels.
     */
    this(size_t ownerID, float bounceHeight)
    {
        super(ownerID);
        this.bounceHeight = bounceHeight;
    }

    /**
     * Set the new bounce height.
     *
     * @param height the new height in pixels.
     */
    void SetBounceHeight(float height)
    {
        this.bounceHeight = height;
    }

    /**
     * Get the current bounce height.
     *
     * @return the height in pixels.
     */
    float GetBounceHeight()
    {
        return this.bounceHeight;
    }

    override void Update() {}
}
