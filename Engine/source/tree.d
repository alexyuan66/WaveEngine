import gameobject;
import bindbc.sdl;
import sdl_abstraction;

/**
 * An algorithm for traversing a tree.
 */
interface ITraversalAlgorithm{
    /**
     * Traverse through a tree.
     *
     * @param node the root node.
     * @param operation the operation to perform at each node.
     */
    void Traverse(SceneNode node, void delegate(SceneNode) operation);
}

/**
 * A depth-first-search traversal algorithm.
 *
 * @see ITraversalAlgorithm
 */
class DFS : ITraversalAlgorithm{
    /**
     * Traverse through a tree using DFS
     *
     * @param node the root node.
     * @param operation the operation to perform at each node.
     */
    void Traverse(SceneNode node, void delegate(SceneNode) operation) {
        import std.range;
        import std.array;
        SceneNode[] stack;
        stack ~= node;

        while (!stack.empty()) {
            // retrieve reference to last node and then remove it 
            SceneNode nextNode = stack.back();
            stack = stack[0 .. $-1];

            // Add next node's children
            foreach(childNode; nextNode.children) {
                stack ~= childNode;
            }

            // operate on every node that has a gameobject
            if (nextNode.gameObject !is null){
                operation(nextNode);
            }
        }
    }
}

/**
 * A node in the scene tree.
 *
 * Can be traveres using an ITraversalAlgorithm.
 **/
class SceneNode{
    string name;                /**< The name of the scene tree object. */
    SceneNode parent = null;    /**< The parent SceneNode object (if it exists). */
    SceneNode[] children;       /**< The children SceneNode objects. */
    GameObject gameObject;      /**< The GameObject linked to the current node (if it exists). */

    /**
     * Initialize a new scene tree node.
     *
     * @param name the name of the node.
     * @param gameObject the linked GameObject (optional).
     */
    this(string name, GameObject gameObject = null)
    {
        this.name = name;
        this.gameObject = gameObject;
    }

    /**
     * Add a child SceneNode.
     */
    void addChild(SceneNode node)
    {
        node.parent = this;
        children ~= node;
    }

    /**
     * Recursively update this node's GameObject and all child GameObject nodes.
     *
     * @see GameObject::Update
     */
    void Update()
    {
        if (gameObject)
        {
            gameObject.Update();
        }

        foreach (child; children)
        {
            child.Update();
        }
    }

    /**
     * Recursively render this node's GameObject and all child GameObject nodes.
     *
     * @param renderer the SDL renderer.
     * @param camera the camera location and size.
     * @param ignore_player whether to ignore the player or not.
     *
     * @see GameObject::Render
     */
    void Render(SDL_Renderer* renderer, SDL_Rect* camera, bool ignore_player=false)
    {
        if (gameObject)
        {
            bool isPlayer = gameObject.GetName() == "Player";
            if ((ignore_player && isPlayer) || (!ignore_player && !isPlayer))
            {
                gameObject.Render(renderer, camera);
            }
        }

        foreach (child; children)
        {
            child.Render(renderer, camera, ignore_player);
        }
    }

    /**
     * Recursively find a given node in the scene tree.
     *
     * @param targetName the name of the node to find.
     *
     * @return the first descendent node with the given name.
     */
    SceneNode Find(string targetName) {
        if (name == targetName) {
            return this;
        }

        foreach (child; children)
        {
            auto ret = child.Find(targetName);
            if (ret !is null) {
                return ret;
            }
         }

        return null;
    }
}
