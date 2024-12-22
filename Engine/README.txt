---Instructions to compile/run the Polygon Dash game:

To compile and run the Polygon Dash game itself from source.
LINUX:
cd Engine/
dub

MAC:
cd Engine/
dub --compiler=ldc2


To run the provided compiled binaries, simply execute in terminal:
LINUX:
./prog_sdl_linux_binary

MAC:
./prog_sdl_mac_binary


---Instructions to run level editor engine GUI:

LINUX (type these commands in terminal):
cd Engine/
sudo apt-get install python3-tk python3-pil python3-pil.imagetk
python3 gui.py


MAC (type these commands in terminal):
cd Engine/
brew install tcl-tk
pip install -r requirements.txt
python3 gui.py
