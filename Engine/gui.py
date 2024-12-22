import tkinter as tk
from tkinter import messagebox
from PIL import Image, ImageTk
import json
import os
from settings_panel import SettingsPanel
from object import Object
from sprite import Spritesheet
from util_panel import UtilPanel
from object_details import ObjectDetails

class GridEditor:
    def __init__(self, root):
        self.root = root
        self.grid_size_x = 50
        self.grid_size_y = 10
        self.cell_size = 64
        self.grid_objects = {}
        self.is_painting = False
        self.rotation_angle = tk.IntVar(value=0)
        self.rotation_mapping = {0: 0, 90: 1, 180: 2, 270: 3}
        self.flag_count = 0
        self.current_object = "Square"
        
        # Handle spritesheet management
        self.obj_name_to_spritesheet = {}
        self.load_default_spritesheets()
        self.root.resizable(True, True)
        self.setup_ui()
        
    def object_info(self, event):
        # Open details modal of object on right click
        x, y = self.get_cell_coordinates(event)
        if (x, y) in self.grid_objects:
            obj = self.grid_objects[(x, y)]
            ObjectDetails(self.root, self, obj)
        
    def load_level(self, level_file_path):        
        try:
            with open(level_file_path, "r") as file:
                level_data = json.load(file)
                
            # Load spritesheets and update palette
            spritesheet_map = level_data["config"]["sprite_map"]
            for obj_name, json_path in spritesheet_map.items():
                self.obj_name_to_spritesheet[obj_name] = Spritesheet(obj_name, json_path, self.cell_size)
                self.update_palette_sprite(obj_name)
                
            # Update level width, player speed, gravity, audio path
            self.grid_size_x = level_data["config"]["level_width"]
            self.settings_panel.level_width_control.sb_level_width.set(level_data["config"]["level_width"])
            self.settings_panel.level_width_control.set_level_width()
            self.settings_panel.env_control.player_speed.set(level_data["config"]["player_speed"])
            self.settings_panel.env_control.gravity.set(level_data["config"]["gravity"])
            self.settings_panel.env_control.audio_path = level_data["config"]["audio"]

            # Clear and redraw grid
            self.grid_objects.clear()
            self.canvas.delete("all")  # Remove all objects from the canvas
            self.draw_grid()
                        
            # Load level objects
            for obj in level_data["objects"]:
                x = obj["x"]
                y = obj["y"]
                obj_name = obj["obj_name"]
                angle = obj["angle"] * 90
                self.add_object(x - 5 , 9 - y, obj_name, angle)
                # update bounce height
                if "bounce_height" in obj:
                    self.grid_objects[(x-5,9-y)].properties["bounce_height"] = obj["bounce_height"]
            
            messagebox.showinfo("Success", f"Level loaded from {level_file_path}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load level: {e}")
                
    def add_object(self, x, y, obj_name, angle):
        if (x, y) in self.grid_objects:
            return
        
        if obj_name == "Finish":
            self.flag_count += 1
        
        x1, y1 = x * self.cell_size, y * self.cell_size
        sprite_image = self.obj_name_to_spritesheet[obj_name].get_sprite(0, angle)
        self.canvas.create_image(x1, y1, image=sprite_image, anchor="nw", tags=f"obj-{x}-{y}")
        self.grid_objects[(x, y)] = Object(x, y, obj_name, angle)

    def load_default_spritesheets(self):
        default_obj = [
                       ["Player", "assets/images/player.json"],
                       ["Square", "assets/images/square.json"],
                       ["Triangle", "assets/images/triangle.json"],
                       ["Finish", "assets/images/flag.json"],
                       ["Bouncer", "assets/images/bouncer.json"],
                       ["GravityFlipper", "assets/images/gravityflipper.json"],
                       ["SizeFlipper", "assets/images/sizeflipper.json"]]
        
        for obj_name, json_path in default_obj:
            self.obj_name_to_spritesheet[obj_name] = Spritesheet(obj_name, json_path, self.cell_size)

    def setup_ui(self):
        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_columnconfigure(1, weight=0)
        self.root.grid_rowconfigure(0, weight=1)
        
        # Settings Panel
        self.settings_panel = SettingsPanel(self.root, self)
        self.settings_panel.grid(row=0, column=0, sticky="w")

        # Grid Canvas Frame
        self.canvas_frame = tk.Frame(self.root)
        self.canvas_frame.grid(row=0, column=1, sticky="nsew")
        
        # Canvas
        self.canvas = tk.Canvas(self.canvas_frame, width=10 * self.cell_size, height=10 * self.cell_size, 
                                bg="white", scrollregion=(0, 0, self.grid_size_x * self.cell_size, self.grid_size_y * self.cell_size))
        self.canvas.grid(row=0, column=2, sticky="nsew")
        self.canvas.bind("<Button-1>", self.start_painting)
        self.canvas.bind("<B1-Motion>", self.paint_object)
        self.canvas.bind("<ButtonRelease-1>", self.stop_painting)
        self.canvas.bind("<Button-2>", self.object_info)
        self.canvas.bind("<Button-3>", self.object_info)

        # Grid Scrollbar
        self.scrollbar = tk.Scrollbar(self.canvas_frame, orient="horizontal", command=self.canvas.xview)
        self.scrollbar.grid(row=1, column=2, sticky="ew")
        self.canvas.config(xscrollcommand=self.scrollbar.set)

        self.draw_grid()
        
        #Palette
        self.add_palette()
        
        self.util_panel = UtilPanel(self.root, self)
        self.util_panel.grid(row=2, column=2, sticky='e')

    def draw_grid(self):
        for x in range(0, self.grid_size_x * self.cell_size, self.cell_size):
            for y in range(0, self.grid_size_y * self.cell_size, self.cell_size):
                self.canvas.create_rectangle(x, y, x + self.cell_size, y + self.cell_size, outline="gray")

    def add_palette(self):
        palette_bg = "#f0f0f0"

        palette_container = tk.Frame(self.root, bg=palette_bg)
        palette_container.grid(row=0, column=2, sticky="nsew", padx=10, pady=10)

        self.root.grid_rowconfigure(0, weight=1, minsize=100) 
        self.root.grid_columnconfigure(1, weight=0)  

        palette_container.grid_rowconfigure(0, weight=1)  
        palette_container.grid_columnconfigure(0, weight=1) 

        # Palette canvas 
        canvas = tk.Canvas(palette_container, bg=palette_bg, width=210, highlightthickness=0)
        canvas.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)

        # Scrollbar 
        scrollbar = tk.Scrollbar(palette_container, orient="vertical", command=canvas.yview)
        scrollbar.grid(row=0, column=1, sticky="nsew")
        canvas.config(yscrollcommand=scrollbar.set)

        # Palette frame 
        palette_frame = tk.Frame(canvas, bg=palette_bg)

        # Create a window inside the canvas to hold the frame
        canvas.create_window((0, 0), window=palette_frame, anchor="nw")

        palette_frame.grid_rowconfigure(0, weight=1, minsize=50)
        palette_frame.grid_columnconfigure(0, weight=1)  

        palette_frame.bind("<Configure>", lambda event: canvas.configure(scrollregion=canvas.bbox("all")))
        self.palette_frame = palette_frame

        tk.Label(palette_frame, text="Palette", font=("Arial", 14, "bold"), bg=palette_bg).pack(pady=10)

        self.selected_object = tk.StringVar(value="square")

        # Palette items
        for obj_name, spritesheet in self.obj_name_to_spritesheet.items():
            if obj_name != "Player":
                self.create_palette_row(palette_frame, obj_name, spritesheet.get_sprite(0, 0))

        self.create_eraser_row(palette_frame)

    def update_current_object(self, obj_name):
        self.set_current_object(obj_name)
        self.settings_panel.spritesheet_control.display_spritesheet()

    def create_palette_row(self, palette_frame, obj_name, sprite):
        row_frame = tk.Frame(palette_frame, pady=5, padx=5) 
        row_frame.pack(fill="x", pady=5)

        sprite_image = tk.Label(row_frame, image=sprite)
        sprite_image.pack(side="left", padx=5)

        text_label = tk.Label(row_frame, text=obj_name)
        text_label.pack(side="left", padx=5)

        radio_button = tk.Radiobutton(row_frame, variable=self.selected_object, value=obj_name, 
                                      command=lambda: self.update_current_object(obj_name))
        radio_button.pack(side="right", padx=5)

        row_frame.bind("<Button-1>", lambda event, rb=radio_button: rb.invoke())
        sprite_image.bind("<Button-1>", lambda event, rb=radio_button: rb.invoke())
        text_label.bind("<Button-1>", lambda event, rb=radio_button: rb.invoke())

    def create_eraser_row(self, palette_frame):
        eraser_frame = tk.Frame(palette_frame, pady=5, padx=5)
        eraser_frame.pack(fill="x", pady=5)

        eraser_image = ImageTk.PhotoImage(Image.open("./assets/images/eraser.png").resize((self.cell_size, self.cell_size)))
        eraser_label = tk.Label(eraser_frame, image=eraser_image)
        eraser_label.image = eraser_image
        eraser_label.pack(side="left", padx=5)

        eraser_text_label = tk.Label(eraser_frame, text="Eraser")
        eraser_text_label.pack(side="left", padx=5)

        radio_button = tk.Radiobutton(eraser_frame, variable=self.selected_object, value="eraser", 
                                      command=lambda: self.set_current_object("eraser"))
        radio_button.pack(side="right", padx=5)

        eraser_frame.bind("<Button-1>", lambda event, rb=radio_button: rb.invoke())
        eraser_label.bind("<Button-1>", lambda event, rb=radio_button: rb.invoke())
        eraser_text_label.bind("<Button-1>", lambda event, rb=radio_button: rb.invoke())
        
    def erase_grid(self):        
        # Clear grid visually
        for x in range(self.grid_size_x):
            for y in range(self.grid_size_y):
                self.erase_object(x, y)

    def set_current_object(self, obj):
        self.current_object = obj

    def start_painting(self, event):
        self.is_painting = True
        self.paint_object(event)

    def stop_painting(self, event):
        self.is_painting = False

    def paint_object(self, event):
        if not self.is_painting or self.current_object is None:
            return

        x, y = self.get_cell_coordinates(event)
        if self.current_object == "eraser":
            self.erase_object(x, y)
        else:
            self.add_object(x, y, self.current_object, self.rotation_angle.get())

    def get_cell_coordinates(self, event):
        canvas_x_offset, _ = self.canvas.xview()
        canvas_y_offset, _ = self.canvas.yview()
        adjusted_x = event.x + (canvas_x_offset * self.grid_size_x * self.cell_size)
        adjusted_y = event.y + (canvas_y_offset * self.grid_size_y * self.cell_size)
        return int(adjusted_x // self.cell_size), int(adjusted_y // self.cell_size)

    def erase_object(self, x, y):
        if (x, y) in self.grid_objects:
            # Decrement flag count
            if self.grid_objects[(x,y)].obj_name == "Finish":
                self.flag_count -= 1
                            
            self.canvas.delete(f"obj-{x}-{y}")
            del self.grid_objects[(x, y)]

    def update_palette_sprite(self, obj_name):
        # Find the correct row in the palette based on object name
        for row in self.palette_frame.winfo_children():
            # The row_frame for each object will have the obj_name as the key
            if len(row.winfo_children()) > 1 and obj_name in row.winfo_children()[1].cget("text"):  # Accessing text label
                # Update the sprite image in the palette row
                label = row.winfo_children()[0]  # The label holding the image
                new_image = self.obj_name_to_spritesheet[obj_name].get_sprite(0, 0)
                label.config(image=new_image)  # Update image
                label.image = new_image  # Keep a reference to the image
                break    

    def update_grid_with_new_sprite(self, obj_name):
        # Find all grid objects of this type and update their images
        for (x, y), obj in self.grid_objects.items():
            if obj.obj_name == obj_name:
                # Get the current angle for this object (using the same logic as before)
                angle = self.grid_objects[(x,y)].angle
                new_sprite = self.obj_name_to_spritesheet[obj_name].get_sprite(0, angle)
                
                # Redraw the object with the new sprite
                sprite_image = new_sprite  # Assuming angle is in degrees (0, 90, 180, 270)
                x1, y1 = x * self.cell_size, y * self.cell_size
                self.canvas.create_image(x1, y1, image=sprite_image, anchor="nw", tags=f"obj-{x}-{y}")

if __name__ == "__main__":
    root = tk.Tk()
    app = GridEditor(root)
    root.mainloop()
