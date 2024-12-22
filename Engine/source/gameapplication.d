// Import D standard libraries
import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.random;
import std.range;
import std.algorithm;
import std.json;

// Third-party libraries
import bindbc.sdl;

// Import our SDL Abstraction
import sdl_abstraction;
import component;
import script;
import gameobject;
import factory;
import tree;
import resourcemanager;
import configmanager;
import audio;

/**
 * The type of a given SceneNode.
 */
enum SceneType {
    MENU,   /**< A menu screen. */
    LEVEL   /**< A playable level. */
}

/**
 * Main game application.
 *
 * Contains the game loop and scene structures.
 */
struct GameApplication {
    SDL_Window* mWindow = null;         /**< The SDL window. */
	SDL_Renderer* mRenderer = null;     /**< The SDL renderer. */
	bool mGameIsRunning = true;         /**< Whether the game is running. */
    string currentLevelName;            /**< The name of the current level. */
    uint max_frame_duration;            /**< The maximum time available until the next frame must render. */
    SDL_Rect* mCamera = null;           /**< The camera placement and size. */

    // Scene Management
    SceneNode[] scenes;         /** All available scenes in the game. */
    SceneNode root;             /** The root of the current scene tree. */
    SceneNode startButtonNode;  /** A pointer to the start button scene tree node if it exists in the current scene. */
    SceneNode playerNode;       /** A pointer to the player GameObject node if it exists in the current scene. */
    SceneNode collidableNode;   /** A pointer to the collection of collidable GameObjects if it exists in the current scene. */
    SceneNode finishLineNode;   /** A pointer to the finidh line GameObject node if it exists in the current scene. */
    SceneNode attemptNode;      /** A pointer to the attempt label node if it exists in the current scene. */

    // Sounds
    AudioManager audioManager;  /**< The AudioManager for the game. */
    string currentScene;        /**< The name of the current scene. */

    int WINDOW_HEIGHT = 480;    /** The height of the game window. */
    int WINDOW_WIDTH = 640;     /** The width of the game window. */

    /**
     * Initialize a new game.
     *
     * @param title the title of the game window.
     * @param fps the maximum FPS allowed for the game.
     */
	this(string title, uint fps)
    {
		// Create an SDL window
		mWindow = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);

		// Create a hardware accelerated mRenderer
		mRenderer = SDL_CreateRenderer(mWindow,-1,SDL_RENDERER_ACCELERATED);

        // Create sounds.
        audioManager = new AudioManager();
        audioManager.AddAudioResource("lobbySound", "assets/sound/lobby_music.wav");
        audioManager.AddAudioResource("clickSound","assets/sound/click.wav" );
        audioManager.AddAudioResource("playerDeathSound", "assets/sound/player_death.wav");
        audioManager.PlayIndefinitely("lobbySound");
        currentScene = "Menu";

        // Calculate maximum frame duration to frame cap in milliseconds.
		max_frame_duration = 1000 / fps;

        mCamera = new SDL_Rect(0, 0, 640, 480);
        PushScene(SceneType.MENU, to!string(0));
        LoadScene();
    }

    /**
     * Cleanup the game when destroyed.
     */
	~this()
    {
		// Destroy our renderer
		SDL_DestroyRenderer(mRenderer);
		// Destroy our window
		SDL_DestroyWindow(mWindow);
	}

    /**
     * Add a new scene to the list of scenes.
     *
     * @param scene_type the type of scene to add.
     * @param level the name of the scene being added.
     *
     * @see #scenes
     */
    void PushScene(SceneType scene_type, string level){
        if (scene_type == SceneType.MENU){
            switch(level) {
                case "0":
                    scenes ~= CreateMenuScene();
                    break;
                case "1":
                    scenes ~= CreateDefaultLevelsMenuScene();
                    break;
                case "2":
                // TODO: Custom Level Menu
                    break;
                default:
                    break;
            } 
        } else if (scene_type == SceneType.LEVEL) {
            scenes ~= CreateLevelScene(level);
        }
        currentLevelName = level;
    }

    /**
     * Pop the last scene in the listt off.
     *
     * @see #scenes
     */
    void PopScene(){
        scenes.popBack();
    }

    /**
     * Load the current scene data into the game.
     *
     * This loads the data from #root into the other node pointers.
     * @see #root
     */
    void LoadScene(){
        root = scenes[scenes.length - 1];

        if (root.name == "Menu") {
            // Change background music.
            if (currentScene == "Level")
            {
                audioManager.StopBackgroundMusic();
                audioManager.StopAllEffects();
                audioManager.PlayIndefinitely("lobbySound");
            }
            auto scene_start_button_node = root.Find("Start Button");
            if (scene_start_button_node !is null) {
                startButtonNode = scene_start_button_node;
            }
            currentScene = root.name;
        } else if (root.name == "Level") {
            // Change background music.
            audioManager.StopBackgroundMusic();
            audioManager.StopAllEffects();
            audioManager.PlayIndefinitely("currLevelSound");

            // Set player pointer if it exists
            auto scene_player_node = root.Find("Player");
            if (scene_player_node !is null) {
                playerNode = scene_player_node;
            }

            // Set collidable pointer if it exists
            auto scene_collidable_node = root.Find("Collidable");
            if (scene_collidable_node !is null)
            {
                collidableNode = scene_collidable_node;
            }

            // Set finish line pointer if it exists
            auto scene_finish_line_node = root.Find("Finish");
            if (scene_finish_line_node !is null)
            {
                finishLineNode = scene_finish_line_node;
            }

            // Set attempts pointer if it exists
            auto attempt_node = root.Find("Attempt");
            if (attempt_node !is null)
            {
                attemptNode = attempt_node;
            }
            currentScene = "Level";
        }

        // Reset Camera on new scene load
        mCamera.x = 0;
        mCamera.y = 0;
    }

    /**
     * Create a SceneNode for the main menu.
     *
     * @return the newly created scene.
     *
     * @see SceneNode
     */
    SceneNode CreateMenuScene(){
        // Create scene tree.
        SceneNode new_root = new SceneNode("Menu");
        auto title = GameObjectFactory("Static Text", mRenderer, mCamera.w / 2 - 110, mCamera.h / 5);
        auto text_render_component = title.GetComponent(ComponentType.TEXT_RENDER);
        (cast(ComponentTextRenderer)text_render_component).mText = "Polygon   Dash";

        // Set up menu buttons
        auto defaultButton = ButtonFactory.CreateStaticButton("Default Button", (){
            PushScene(SceneType.MENU, to!string(1));
            LoadScene();
            audioManager.PlayEffect("clickSound");
        }, mRenderer, mCamera.w / 2 - 64, mCamera.h / 5 * 2, 128, 64, "assets/images/default.json", mCamera);
        auto customButton = ButtonFactory.CreateStaticButton("Custom Button", (){
            import std.file;
            if (exists("assets/levels/custom_level.json")) {
                PushScene(SceneType.LEVEL, "custom_level");
                LoadScene();
                audioManager.PlayEffect("clickSound");
            }
        }, mRenderer, mCamera.w / 2 - 92, mCamera.h / 5 * 3, 196, 64, "assets/images/custom.json", mCamera);

        new_root.addChild(new SceneNode("Title", title));
        new_root.addChild(new SceneNode("Default Button", defaultButton));
        new_root.addChild(new SceneNode("Custom Button", customButton));
        return new_root;
    }

    /**
     * Create a SceneNode for the level selector menu.
     *
     * @return the newly created scene.
     *
     * @see SceneNode
     */
    SceneNode CreateDefaultLevelsMenuScene(){
        // Create scene tree.
        auto title = GameObjectFactory("Static Text", mRenderer, mCamera.w / 2 - 110, mCamera.h / 5);
        auto text_render_component = title.GetComponent(ComponentType.TEXT_RENDER);
        (cast(ComponentTextRenderer)text_render_component).mText = "Default Levels";

        SceneNode new_root = new SceneNode("Menu");
        // Loading level one only for now, will load other levels later
        auto levelOne = ButtonFactory.CreateTextButton("Level 1", "Level 1", (){
            PushScene(SceneType.LEVEL, to!string(1));
            LoadScene();
            audioManager.PlayEffect("clickSound");
        }, mRenderer, mCamera.w / 2 - 110, mCamera.h * 2 / 5, mCamera);

        auto levelTwo = ButtonFactory.CreateTextButton("Level 2", "Level 2", (){
           PushScene(SceneType.LEVEL, to!string(2));
           LoadScene();
           audioManager.PlayEffect("clickSound");
        }, mRenderer, mCamera.w / 2 - 110, mCamera.h * 2 / 5 + 64, mCamera);

        auto levelThree = ButtonFactory.CreateTextButton("Level 3", "Level 3", (){
            PushScene(SceneType.LEVEL, to!string(3));
            LoadScene();
            audioManager.PlayEffect("clickSound");
        }, mRenderer, mCamera.w / 2 - 110, mCamera.h * 2 / 5 + 128, mCamera);

        auto backButton = ButtonFactory.CreateStaticButton("Back Button", (){
            PopScene();
            LoadScene();
            audioManager.PlayEffect("clickSound");
        }, mRenderer, 10, 10, 64, 64, "assets/images/back.json", mCamera);

        new_root.addChild(new SceneNode("Default Levels Menu Title", title));
        new_root.addChild(new SceneNode("Level One", levelOne));
        new_root.addChild(new SceneNode("Level Two", levelTwo));
        new_root.addChild(new SceneNode("Level Three", levelThree));
        new_root.addChild(new SceneNode("Back Button", backButton));
        return new_root;
    }

    /**
     * Create a SceneNode for a game level.
     *
     * @param level the level name to load.
     *
     * @return the newly created scene.
     *
     * @see SceneNode
     */
    SceneNode CreateLevelScene(string level)
    {
        File myFile = File("assets/levels/" ~ level ~ ".json", "r");
        auto jsonFileContents = myFile.byLine.joiner("\n");
        auto j = parseJSON(jsonFileContents);

        // Create config settings.
        auto configSettings = j["config"];
        // ConfigManager.ClearInstance();
        audioManager.AddAudioResource("currLevelSound", configSettings["audio"].get!string);
        ConfigManager.GetInstance().SetGravity(configSettings["gravity"].get!float);
        ConfigManager.GetInstance().SetCellSize(configSettings["cell_size"].get!int);
        ConfigManager.GetInstance().SetPlayerSpeed(configSettings["player_speed"].get!int);
        foreach (key, value; configSettings["sprite_map"].object)
        {
            string spriteName = key;
            string spritePath = value.get!string;
            ConfigManager.GetInstance().SetSpritePath(spriteName, spritePath);
        }


        // Create scene tree.
        SceneNode new_root = new SceneNode("Level");
        SceneNode static_objects = new SceneNode("Static");
        SceneNode collidable_objects = new SceneNode("Collidable");
        auto player = GameObjectFactory("Player", mRenderer, 180, WINDOW_HEIGHT - ConfigManager.GetInstance().LoadCellSize());
        new_root.addChild(new SceneNode("Player", player));

        auto attempt = GameObjectFactory("Attempt", mRenderer, 360, WINDOW_HEIGHT - 400);
        new_root.addChild(new SceneNode("Attempt", attempt));

        // Create game objects.
        auto levelObjectsArray = j["objects"].array;
        foreach (levelObject; levelObjectsArray)
        {
            int x = levelObject["x"].get!int * ConfigManager.GetInstance().LoadCellSize();
            int y = WINDOW_HEIGHT - ((levelObject["y"].get!int + 1) * ConfigManager.GetInstance().LoadCellSize());
            int rotation = levelObject["angle"].get!int;
            string type = levelObject["obj_name"].get!string;
            if (type == "Finish")
            {
                auto obj = GameObjectFactory(type, mRenderer, x, y, rotation);
                new_root.addChild(new SceneNode(type, obj));
            } 
            else if (type == "Static1" || type == "Static2")
            {
                auto obj = GameObjectFactory(type, mRenderer, x, y, rotation);
                static_objects.addChild(new SceneNode(type, obj));
            }
            else
            {
                if (type == "Bouncer")
                {
                    ConfigManager.GetInstance().SetBounceHeight(-levelObject["bounce_height"].get!float);
                }
                auto obj = GameObjectFactory(type, mRenderer, x, y, rotation);
                collidable_objects.addChild(new SceneNode(type, obj));
            }
        }

        new_root.addChild(static_objects);
        new_root.addChild(collidable_objects);

        // Add back button
        auto backButton = ButtonFactory.CreateStaticButton("Back Button", (){
            PopScene();
            LoadScene();
        }, mRenderer, 10, 10, 64, 64, "assets/images/back.json", mCamera);
        auto playerMovementComponent = new ComponentPlayerMovement(backButton.GetID(), cast(ComponentTransform)backButton.GetComponent(ComponentType.TRANSFORM));
        backButton.AddScript!(ScriptType.PLAYER_MOVEMENT)(playerMovementComponent);
        new_root.addChild(new SceneNode("Back Button", backButton));

        return new_root;
    }

    /**
     * Read and store keyboard and mouse input.
     *
     * This input can be accessed by IComponent and ComponentScript objects.
     *
     * @see GameObject
     * @see IComponent
     * @see ComponentScript
     */
	void Input()
    {
		SDL_Event event;
		// Start our event loop
		while(SDL_PollEvent(&event))
        {
			// Handle each specific event
			if(event.type == SDL_QUIT)
            {
				mGameIsRunning = false;
			}

            else if(event.type == SDL_MOUSEBUTTONUP){
                CheckClickables();
            }
		}
    }


    /**
     * Update the state of all GameObject components (both IComponent and ComponentScript objects).
     *
     * 1. Check whether the game is running.
     * 2. Modify the player's jump velocity so they will land on the ground and not pass through.
     * 3. Check for collisions with enemy objects.
     * 4. Update everything else.
     * 5. Move the camera.
     *
     * @see GameObject
     * @see IComponent
     * @see ComponentScript
     */
    void Update()
    {
        // // For menus
        // if (root.name == "Menu") {
        //     CheckClickables();
        // }

        // This logic only applies to levels
        if (root.name == "Level") {
            // Check if game is still active.
            UpdateGameIsRunning();

            // First, un-ground the player
            UngroundPlayer();

            // Check whether we landed on an object or not
            CheckForLanding();

            // Update Collisions
            UpdateCollisions();
        }

        // Update all nodes recursively.
        root.Update();

        if (root.name == "Level")
        {
            mCamera.x += ConfigManager.GetInstance().LoadPlayerSpeed();
        }
    }

    /**
     * Check all clickable objects for click events.
     */
    void CheckClickables()
    {
        auto performClickables = new DFS();
        SceneNode target_scene_tree = scenes[scenes.length - 1];
        performClickables.Traverse(target_scene_tree, (SceneNode node){
            GameObject game_obj = node.gameObject;
            // Handle standard game object clicks
            if (game_obj !is null && game_obj.GetScript(ScriptType.MOUSE_CLICK) !is null) {
                auto clickComponent = cast(ComponentTransformMouseClick)(game_obj.GetScript(ScriptType.MOUSE_CLICK));
                clickComponent.LeftMouseClick();
            }
            // Handle font text clicks
            else if (game_obj !is null && game_obj.GetScript(ScriptType.TEXT_MOUSE_CLICK) !is null) {
                auto clickComponent = cast(ComponentTextMouseClick)(game_obj.GetScript(ScriptType.TEXT_MOUSE_CLICK));
                clickComponent.LeftMouseClick();
            }
        });
    }

    /**
     * Check whether the game should continue running.
     *
     * Updates #mGameIsRunning appropriately.
     *
     * @see #mGameIsRunning
     */
    void UpdateGameIsRunning()
    {
        // If the player died, reload the current scene
        auto playerGameObject = playerNode.gameObject;
        auto finishLineGameObject = finishLineNode.gameObject;
        if (!playerGameObject.IsActive()) {
            // Get previous attempts before reset
            auto prevAttemptComponent = cast(ComponentAttempt)attemptNode.gameObject.GetComponent(ComponentType.ATTEMPT);
            int prev_attempt = prevAttemptComponent.getAttempt();
            PopScene();
            PushScene(SceneType.LEVEL, currentLevelName);
            audioManager.StopBackgroundMusic();
            audioManager.PlayEffect("playerDeathSound");
            SDL_Delay(1500);
            LoadScene();

            // Handle increment attempts
            auto newAttemptComponent = cast(ComponentAttempt)attemptNode.gameObject.GetComponent(ComponentType.ATTEMPT);
            newAttemptComponent.setAttempt(prev_attempt + 1);
        }

        // If the player passed the finish line, win
        if (playerGameObject.IsActive() && finishLineGameObject.IsActive()) {
            auto playerTransform = cast(ComponentTransform)(playerGameObject.GetComponent(ComponentType.TRANSFORM));
            auto finishLineTransform = cast(ComponentTransform)(finishLineGameObject.GetComponent(ComponentType.TRANSFORM));

            if (playerTransform.rect.x >= finishLineTransform.rect.x + finishLineTransform.rect.w) {
                PopScene();
                LoadScene();
            }
        }
    }

    /**
     * Marks the player as free falling.
     *
     * @see #playerNode
     */
    void UngroundPlayer() {
        auto playerGameObject = playerNode.gameObject;
        auto playerJump = cast(ComponentPlayerInputJump)(playerGameObject.GetScript(ScriptType.PLAYER_JUMP));

        if (playerGameObject.IsActive()) playerJump.ResetGrounded();
    }

    /**
     * Checks whether the player will land on an object due to gravity, and restricts its motion if so.
     *
     * If the player will not hit the ground, take no action.
     * Otherwise, ensure the player will not pass through.
     *
     * @see #playerNode
     * @see ComponentCollision::CheckForFloorCollision
     */
    void CheckForLanding()
    {
        auto playerGameObject = playerNode.gameObject;
        auto playerCollision = cast(ComponentCollision)(playerGameObject.GetScript(ScriptType.COLLISION));

        // We only need to check collisions between player and square objects
        foreach (node; collidableNode.children)
        {
            if (node.gameObject && node.gameObject.GetName() == "Square" && node.gameObject.IsActive())
            {
                playerCollision.CheckForFloorCollision(node.gameObject, mCamera);
            }
        }
    }

    /**
     * Checks whether the player hit any enemy objects.
     *
     * @see #playerNode
     * @see ComponentCollision::HandleCollision
     */
    void UpdateCollisions()
    {
        auto playerGameObject = playerNode.gameObject;
        auto playerCollision = cast(ComponentCollision)(playerGameObject.GetScript(ScriptType.COLLISION));

        // We only need to check collisions between player and collidable objects
        foreach (node; collidableNode.children) {
            if (node.gameObject && node.gameObject.IsActive()) {
                playerCollision.HandleCollision(node.gameObject, mCamera);

                // If the player is not active, no need to check everything else
                if (!playerGameObject.IsActive())
                    return;
            }
        }
    }

    /**
     * Render all GameObject entities.
     */
    void Render()
    {
		SDL_SetRenderDrawColor(mRenderer,200,200,200,SDL_ALPHA_OPAQUE);
        SDL_RenderClear(mRenderer);
        root.Render(mRenderer, mCamera, false);
        root.Render(mRenderer, mCamera, true);
        SDL_RenderPresent(mRenderer);
    }

    /**
     * Take one frame's worth of actions.
     *
     * Calling this function runs the game loop once.
     */
    void AdvanceFrame()
    {
        Input();
        Update();
        Render();
    }

    /**
     * Run the game.
     *
     * This is the entry point into the game.
     * This function runs the game loop on repeat.
     */
    void RunLoop()
    {
        // Main application loop
        uint num_frames = 0;
        uint last_title_update = SDL_GetTicks();

        while(mGameIsRunning)
        {
            uint last_time = SDL_GetTicks();
            AdvanceFrame();
            uint end_time = SDL_GetTicks();
            uint elapsed_time = end_time - last_time;

            // Framecap application at 60FPS.
            if (elapsed_time < max_frame_duration)
            {
                SDL_Delay(max_frame_duration - elapsed_time);
            }

            // Output the frames per second on the title bar every second.
            num_frames++;
            if (end_time - last_title_update >= 1000)
            {
                string title = "Frames Per Second: " ~ num_frames.to!string;
                SDL_SetWindowTitle(mWindow, title.toStringz());
                num_frames = 0;
                last_title_update = end_time;
            }
        }
    }
}
