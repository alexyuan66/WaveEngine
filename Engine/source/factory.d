import component;
import script;
import gameobject;
import bindbc.sdl;
import std.stdio;
import std.conv;

import configmanager;

/**
 * Create a GameObject based on a preset configuration.
 *
 * @param name the type of GameObject to create.
 * @param renderer the SDL renderer object.
 * @param xPosition the initial x coordinate of the GameObject in pixels.
 * @param yPosition the initial y coordinate of the GameObject in pixels.
 * @param rotation the initial rotation of the GameObject in degrees (default: 0).
 *
 * @return the configured GameObject.
 *
 * @see GameObject
 */
GameObject GameObjectFactory(string name, SDL_Renderer* renderer, int xPosition, int yPosition, int rotation=0)
{
	// Create our game object
	GameObject go = new GameObject(name);

    if (name == "Player")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
        auto playerMovementComponent = new ComponentPlayerMovement(go.GetID(), transformComponent);
        go.AddScript!(ScriptType.PLAYER_MOVEMENT)(playerMovementComponent);
        auto inputJumpComponent = new ComponentPlayerInputJump(go.GetID(), transformComponent, renderComponent);
        go.AddScript!(ScriptType.PLAYER_JUMP)(inputJumpComponent);
        auto collisionComponent = new ComponentCollision(go.GetID(), transformComponent, inputJumpComponent, &go.mActive);
        go.AddScript!(ScriptType.COLLISION)(collisionComponent);
    }
    else if (name == "Square")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
    }
    else if (name == "Triangle")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
    }
    else if (name == "Bouncer")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
        auto bounceComponent = new ComponentBounce(go.GetID(), ConfigManager.GetInstance().LoadBounceHeight());
        go.AddScript!(ScriptType.BOUNCE_HEIGHT)(bounceComponent);
    }
    else if (name == "GravityFlipper")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
    }
    else if (name == "SizeFlipper")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
    }
    else if (name == "Finish")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, ConfigManager.GetInstance().LoadCellSize(), ConfigManager.GetInstance().LoadCellSize());
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
    }
    else if (name == "Static1")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, 200, 200);
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
        auto movementComponent = new ComponentParallaxScroll(go.GetID(), 1, transformComponent);
        go.AddScript!(ScriptType.PARALLAX)(movementComponent);
    }
    else if (name == "Static2")
    {
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, 500, 300);
        transformComponent.SetRotationAngle(cast(float)(rotation % 4) * 90.0f);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, ConfigManager.GetInstance().LoadSpritePath(name));
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);
        auto movementComponent = new ComponentParallaxScroll(go.GetID(), 2, transformComponent);
        go.AddScript!(ScriptType.PARALLAX)(movementComponent);
    }
    else if (name == "Attempt")
    {
        string textFontPath = "assets/fonts/arcade.TTF";
        SDL_Color textColor = SDL_Color(255, 255, 255, 255);
        auto textRendererComponent = new ComponentTextRenderer(go.GetID(), renderer, textFontPath, 48, textColor, xPosition, yPosition);
        go.AddComponent!(ComponentType.TEXT_RENDER)(textRendererComponent);
        auto attemptComponent = new ComponentAttempt(go.GetID(), textRendererComponent);
        go.AddComponent!(ComponentType.ATTEMPT)(attemptComponent);
    }
    else if (name == "Static Text")
    {
        string textFontPath = "assets/fonts/arcade.TTF";
        SDL_Color textColor = SDL_Color(255, 255, 255, 255);
        auto textRendererComponent = new ComponentTextRenderer(go.GetID(), renderer, textFontPath, 36, textColor, xPosition, yPosition);
        go.AddComponent!(ComponentType.TEXT_RENDER)(textRendererComponent);
    }
    else
    {
        assert(0, "Unknown object name: " ~ name);
    }

	return go;
}

/**
 * Create button GameObjects that receive a click event.
 *
 * @see GameObject
 */
class ButtonFactory{
    /**
    * Create a texture-based button.
    *
    * @param objectName the type of GameObject to create.
    * @param callback the function to call when the button is clicked.
    * @param renderer the SDL renderer object.
    * @param xPosition the initial x coordinate of the GameObject in pixels.
    * @param yPosition the initial y coordinate of the GameObject in pixels.
    * @param width the button width in pixels.
    * @param height the button height in pixels.
    * @param jsonPath the path to the animation's JSON configuration file.
    * @param camera the viewport camera SDL rectangle object.
    *
    * @return the configured GameObject.
    *
    * @see GameObject
    */
    static GameObject CreateStaticButton(string objectName, void delegate() callback, SDL_Renderer* renderer, int xPosition, int yPosition, int width, int height, string jsonPath, SDL_Rect* camera){
        GameObject go = new GameObject(objectName);
        auto transformComponent = new ComponentTransform(go.GetID(), xPosition, yPosition, width, height);
        go.AddComponent!(ComponentType.TRANSFORM)(transformComponent);
        auto animationComponent = new ComponentAnimation(go.GetID(), renderer, jsonPath);
        go.AddComponent!(ComponentType.ANIMATION)(animationComponent);
        auto renderComponent = new ComponentRender(go.GetID(), renderer, transformComponent, animationComponent);
        go.AddComponent!(ComponentType.RENDER)(renderComponent);

        // Set clickable parameters
        auto mouseClickComponent = new ComponentTransformMouseClick(go.GetID(), callback, transformComponent, camera);
        mouseClickComponent.mTransform = transformComponent;
        go.AddScript!(ScriptType.MOUSE_CLICK)(mouseClickComponent); 

        return go;
    }

    /**
    * Create a text-based button.
    *
    * @param objectName the type of GameObject to create.
    * @param buttonLabel the text to display on the button
    * @param callback the function to call when the button is clicked.
    * @param renderer the SDL renderer object.
    * @param xPosition the initial x coordinate of the GameObject in pixels.
    * @param yPosition the initial y coordinate of the GameObject in pixels.
    * @param camera the viewport camera SDL rectangle object.
    *
    * @return the configured GameObject.
    *
    * @see GameObject
    */
    static GameObject CreateTextButton(string objectName, string buttonLabel, void delegate() callback, SDL_Renderer* renderer, int xPosition, int yPosition, SDL_Rect* camera){
        GameObject go = new GameObject(objectName);

        // Set text data
        string textFontPath = "assets/fonts/arcade.TTF";
        SDL_Color textColor = SDL_Color(255, 255, 255, 255);
        auto textRendererComponent = new ComponentTextRenderer(go.GetID(), renderer, textFontPath, 36, textColor, xPosition, yPosition);
        textRendererComponent.mText = buttonLabel;
        go.AddComponent!(ComponentType.TEXT_RENDER)(textRendererComponent);

        // Set clickable parameters
        auto mouseClickComponent = new ComponentTextMouseClick(go.GetID(), callback, textRendererComponent, camera);
        mouseClickComponent.mTextRenderer = textRendererComponent;
        go.AddScript!(ScriptType.TEXT_MOUSE_CLICK)(mouseClickComponent);

        return go;
    }
}
