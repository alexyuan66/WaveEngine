## Final Project - Part 3

This part is about showing off your work by **building a website** for your portfolio. Read the instructions below for what is needed.

## Step 0 - Engine Architecture Diagram

Your project should have an 'engine architecture' diagram on your website which describes the major components of the engine. Think of this as a high-level diagram you would give an engineer the first day of work so they would know the components and how they interact if they want to modify the engine. 

- Note: Some IDEs can automatically generate these diagrams, though you can draw it yourself and highlight the most important components. See [./media/C4Engine.pdf](./media/C4Engine.pdf) as an example. 
- Note: An 'inhertiance hierarchy' is not the same as a high level 'engine architecture diagram' -- I want to see the 'abstraction layers' and 'systems' implemented. For this course it may not be as detailed as the C4 Engine -- but I should still see some major system components (e.g. run-time game loop. resource manager, scene system, etc.)

## Step 1 - Documentation

Now that you are going to be maintaining the code for 'your game company' for many years, it is important to properly document your code. You will continue to use 'Doxygen' <a href="http://www.doxygen.nl/">(Doxygen webpage)</a> or [Doxypress](https://www.copperspice.com/documentation-doxypress.html) to document the source code and automatically generate .html pages. Your documentation should cover your classes and functions.

An example of a well documented probjects can be found here: 

- https://www.ogre3d.org/docs/api/1.9/
- http://www.horde3d.org/docs/html/_api.html

### Doxygen style comments

Some examples of documentation are listed here: http://www.doxygen.nl/manual/docblocks.html 

Comments within code are in the style of:

```cpp
/*!
 * ... text ...
 */

/*!
 ... text ...
*/

//!
//!... text ...
//!

/*! \brief Brief description.
 *         Brief description continued.
 *
 *  Detailed description starts here.
 */

```
**Note**: A helpful tool to use may be: [Doxywizard](http://www.doxygen.nl/manual/doxywizard_usage.html)

## Step 2 - Build (binary file)
You need to have a compiled binary of your game for your operating system (Either Windows, Mac, or Linux). You can assume a target audience of either a 64-bit Mac, Ubuntu Linux, or a Windows 10 machine. There should additionally be instructions about how to compile your code from source. The compilation should be trivial (running `python build.py` for example, or listing a series of 'apt-get install' in a single command or a script you have built. **Make it trivial** so customers/course staff do not get frustrated :) ).

## Step 3 - Post mortem
A post mortem in games is a look back at what could be improved. Write a brief (2-3 paragraphs) on what could be improved if you had an additional 8 weeks to work on this project. Where would you allocate time, what tools would you build, would you use any different tools, etc.

If we had an additional 8 weeks to work on this project, we would allocate this extra time to push for a few major improvements. The first major improvement we would make is to add "layers" to our
tile editor in our game engine UI. We implemented parallax inside the engine itself to have cool backgrounds for levels, but we realized that this parallax clashed with our grid-based tile system
that we used to represent levels and serialize/deserialize them. Furthermore, since the game engine UI level editor uses a grid system, we would have to represent background parallax another way.
The improvement would be to implement layer tabs in the level editor with a boolean flag that allows you to designate layers as grid or non-grid layers. The non-grid layers could be used to place
background objects for parallax effects in your level while the grid layers would be used to place the normal game tiles. This was an oversight in the original design of our GUI that we didn't consider the complexity of until the end of the project.

The second major improvement that we would undertake is complex tile movement patterns. Taking inspiration from our 2D platformer games like Mario, many of the enemies there have complex movement
patterns (they move in rings, they automatically detect when they can jump upwards to another tile, or they follow the player). While we have a very in-depth gravity manipulation system, we do not
have the capacities currently to support the creation of these complex movement patterns of enemy game objects within our GUI interface. We would make the improvement by adding a way for users to easily perform custom movement scripting and custom AI scripting at the GUI-level to enable this functionality. This would definitely require more heavy-duty work on the interface between our D engine code and our Python GUI code.

In terms of tooling, there is also the consideration that if we had more time, we would switch away from Python for the GUI development. While it allows for quick iteration, as the complexity of the
project has grown, so has the difficulty of the lack of strict typing. Upon reflection, the time saved by using Python for GUI development via its fast iteration was probably balanced out by the numerous bugs
that come as baggage with using a dynamically typed language like Python. Ultimately, the code would be more easily understandable to an outside observer if it was a strongly typed language rather
than a dynamically typed language, and it would likely enable better scalability with respect to compounding complexity as our engine expanded with the new features we mentioned before.



*Edit here a draft of your post mortem here if you like--the final copy goes in your 1-page .html website. Think of this section as a good 'reflection' for what you can improve on your next project you complete.*

## Step 4 - Website

I think it is incredibly important to build a portfolio of your game development works! You will be building a 1 page website(it can be all html) to market your final project (Note: You could re-use this template for your next project, and potentially other personal projects).

The following are the requirements for a 1-page .html website.

1. Provide a 2-3 minute video trailer (preferably a link or embedded YouTube Video) followed by at least 3 screenshots of your game (order matters, video first, then screenshots below)
   - Your video should highlight the data-driven nature of your final project (show your engine and tools in use alongside the game)
3. Your documentation (i.e. a link to your doxygen generated files)
4. **An image** of your engine architecture.
5. A link to your binary
6. A short post mortem (i.e. A few paragraphs describing how you would take the project further, what went well, and what you would change if given another month on the project) should be put together on a 1-page .html page.
7. **DO not** make use install 'npm' and run your website locally -- just provide a simple html page.

This website will be the first place I look to grab your project files and binaries. 

[Please edit and put a link to your website here](./Engine/README.md)
