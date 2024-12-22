// Standard Libraries
import core.atomic;
import std.stdio;
import std.algorithm;
import std.conv;
import std.array;

// Project Libraries
import component;
import script;

// Third-party libraries
import bindbc.sdl;

/**
 * Represents an in-game entity.
 *
 * Each GameObject has components (IComponent) and scripts (ComponentScript) that implement specific behaviors.
 * @see IComponent
 * @see ComponentScript
 */
class GameObject{
	bool mActive = true;	/**< Whether the GameObject is active or not. */
	private bool mEnabled = true; // specific to portals, which only are triggered in the first frame of contact

	/**
	 * Create a new GameObject.
	 *
	 * @param name the name for the GameObject.
	 */
	this(string name)
	{
		assert(name.length > 0);
		mName = name;	
		// atomic increment of number of game objects
		sGameObjectCount.atomicOp!"+="(1);		
		mID = sGameObjectCount; 
	}

	// Destructor
	~this(){}

	/**
	 * Get the name of the GameObject.
	 *
	 * @return the GameObject name.
	 */
	string GetName() const { return mName; }

	/**
	 * Get the ID of the GameObject.
	 *
	 * @return the GameObject id.
	 */
	size_t GetID() const { return mID; }

	/**
	 * Whether the GameObject is active.
	 *
	 * @return `true` if active, `false` otherwise.
	 */
	bool IsActive() {return mActive;}

	/**
	 * Whether the GameObject is enabled.
	 *
	 * @return `true` if enabled, `false` otherwise.
	 */
	bool IsEnabled() {return mEnabled;}

	/**
	 * Set whether the GameObject is active or not.
	 *
	 * @param active whether the GameObject should be active or not.
     */
	void SetActive(bool active)
	{
		mActive = active;
	}

	/**
	 * Set whether the GameObject is enabled or not.
	 *
	 * @param enabled whether the GameObject should be enabled or not.
     */
	void SetEnabled(bool enabled)
	{
		mEnabled = enabled;
	}
	
	/**
	 * Update the state of the GameObject's components and scripts.
	 *
	 * @see GameApplication::Update
	 * @see IComponent::Update
	 * @see ComponentScript::Update
	 */
	void Update()
	{
		if (mActive)
		{
			foreach (component ; mComponents.values)
			{
				component.Update();
			}
			foreach (script ; mScripts)
			{
				script.Update();
			}
		}
	}

	/**
	 * Render the GameObject's components and scripts.
	 *
	 * @see GameApplication::Render
	 * @see IComponent::Render
	 * @see ComponentScript::Render
	 */
	void Render(SDL_Renderer* renderer, SDL_Rect* camera)
	{
		if (mActive)
		{
			foreach (component; mComponents.values)
			{
				component.Render(renderer, camera);
			}
			foreach (script ; mScripts)
			{
				script.Render(renderer, camera);
			}
		}
    }

	/**
	 * Get a specific component of the GameObject.
	 *
	 * @param type the type of IComponent to receive.
	 * @return the given IComponent if it exists.
	 */
	IComponent GetComponent(ComponentType type)
	{
		if(type in mComponents)
		{
			return mComponents[type];
		}
		else
		{
			return null;
		}
	}

	/**
	 * Add a new component to the GameObject
	 *
	 * @param T the type of IComponent to add.
	 * @param component the new IComponent.
	 */
	void AddComponent(ComponentType T)(IComponent component)
	{
		mComponents[T] = component;
	}

	/**
	 * Get a specific script of the GameObject.
	 *
	 * @param type the type of ComponentScript to receive.
	 * @return the given ComponentScript if it exists.
	 */
	ComponentScript GetScript(ScriptType type)
	{
		if(type in mScripts)
		{
			return mScripts[type];
		}
		else
		{
			return null;
		}
	}
	
	/**
	 * Add a new script to the GameObject
	 *
	 * @param T the type of ComponentScript to add.
	 * @param component the new ComponentScript.
	 */
	void AddScript(ScriptType T)(ComponentScript component)
	{
		mScripts[T] = component;
	}
	

	protected:
	// Common components for all game objects
	// Pointers are 'null' by default in DLang.
	// See reference types: https://dlang.org/spec/property.html#init
	IComponent[ComponentType] 	mComponents;
	ComponentScript[ScriptType] mScripts;

	private:
	// Any private fields that make up the game object
	string mName;
	size_t mID;

	static shared size_t sGameObjectCount = 0;
}
