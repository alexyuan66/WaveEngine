import tkinter as tk
from tkinter import messagebox, filedialog
from PIL import Image, ImageTk
from tkinter.ttk import Combobox
import json
import os
from sprite import Spritesheet

class LevelWidthControl(tk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        
        self.settings_panel = parent
        
        ### Level Width
        # Level Width Label
        self.label = tk.Label(self, text="Set Level Width", font=("Arial", 12, "bold"))
        self.label.grid(row=0, column=0, padx=10, pady=0, sticky="w")

        # Level Width Textbox
        self.sb_level_width = tk.IntVar()
        
        self.sb = tk.Spinbox(self, from_=10, to=100, wrap=True, textvariable=self.sb_level_width)
        self.sb.grid(row=1, column=0, padx=10, pady=10, sticky="w")
        self.sb_level_width.set(self.settings_panel.editor.grid_size_x)
        
        # Level Width Submit
        self.btn = tk.Button(self, text="Set Level Width", command=self.set_level_width)
        self.btn.grid(row=2, column=0, padx=10, pady=0, sticky="w")
        
    def set_level_width(self):
        editor = self.settings_panel.editor
        
        # Remove objects past new grid width if new_x < old_x
        new_x = int(self.sb.get())
        if new_x < editor.grid_size_x:
            for x in range(new_x, editor.grid_size_x+1):
                for y in range(editor.grid_size_y):
                    editor.erase_object(x, y)
        
        # Update grid width
        editor.grid_size_x = new_x

        # Update canvas scroll region
        editor.canvas.config(scrollregion=(0, 0, editor.grid_size_x * editor.cell_size, editor.grid_size_y * editor.cell_size))

        # Redraw grid
        editor.draw_grid()

class LevelUploadControl(tk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        
        self.settings_panel = parent
        
        load_label = tk.Label(self, text="Load Level", font=("Arial", 12, 'bold'))
        load_label.grid(row=0, column=0, padx=10, sticky="w")

        browse_button = tk.Button(self, text="Browse", command=self.browse_level_file)
        browse_button.grid(row=1, column=0, padx=10, pady=0, sticky="w")
        
    def browse_level_file(self):
        file_path = filedialog.askopenfilename(title="Select a Level", filetypes=(("JSON files", "*.json"), ("All files", "*.*")))
        # Invalid file type
        if not file_path.endswith('.json'):
            messagebox.showerror("Invalid Level", "Please select a JSON file.")
            return
        
        self.settings_panel.editor.load_level(file_path)


class UploadSpritesheetControl(tk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        
        self.settings_panel = parent
        
        # Section label
        upload_label = tk.Label(self, text="Upload a Spritesheet", font=("Arial", 12, 'bold'))
        upload_label.grid(row=0, column=0, padx=10, sticky="w")
        
        # Create the Combobox
        self.cb = Combobox(self, values=[sprite_name for sprite_name in self.settings_panel.editor.obj_name_to_spritesheet.keys()])
        self.cb.set("Square")  # Optionally set a default value
        self.cb.grid(row=1, column=0, padx=10, pady=10, sticky="w")
        
        # Browse for json
        browse_button = tk.Button(self, text="Browse", command=self.browse_spritesheet_file)
        browse_button.grid(row=2, column=0, padx=10, sticky="w")

    def browse_spritesheet_file(self):
        file_path = filedialog.askopenfilename(title="Select a Level", filetypes=(("JSON files", "*.json"), ("All files", "*.*")))
        # Invalid file type
        if not file_path.endswith('.json'):
            messagebox.showerror("Invalid Level", "Please select a JSON file.")
            return
        
        #truncate file path
        truncate_idx = file_path.find("assets/images/")
        file_path = file_path[truncate_idx:]
        
        editor = self.settings_panel.editor
        obj_name = self.cb.get()
        
        
        # Load new spritesheet for sprite
        editor.obj_name_to_spritesheet[obj_name] = Spritesheet(obj_name, file_path, editor.cell_size)
        
        # Update the palette to show the new sprite
        editor.update_palette_sprite(obj_name)  # Assuming new_sprite[0] is the first angle (0 degrees)
        
        # Update all objects of this type on the grid
        editor.update_grid_with_new_sprite(obj_name)
      
class EnvControl(tk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, kwargs)
        self.editor = parent.editor
        self.audio_path = "assets/sound/default_level.wav"
        
        load_label = tk.Label(self, text="Environment Variables", font=("Arial", 12, 'bold'))
        load_label.grid(row=0, column=0, padx=10, sticky="w")
        
        self.gravity = tk.DoubleVar()
        
        gravity_label = tk.Label(self, text="Gravity:")
        gravity_label.grid(row=1, column=0, pady=5)  # Add some vertical space

        gravity_entry = tk.Entry(self, textvariable=self.gravity)
        gravity_entry.grid(row=1, column=1, padx=20)  # Add some vertical space

        self.player_speed = tk.IntVar()
    
        player_speed_label = tk.Label(self, text="Player Speed:")
        player_speed_label.grid(row=2, column=0, pady=5)

        player_speed_entry = tk.Entry(self, textvariable=self.player_speed)
        player_speed_entry.grid(row=2, column=1, padx=20)
            
        audio_label = tk.Label(self, text="Level Audio:")
        audio_label.grid(row=3, column=0, pady=5)
        
        browse_button = tk.Button(self, text="Browse", command=self.browse_audio_file)
        browse_button.grid(row=3, column=1, padx=18, sticky="w")
        
        # Default values
        self.gravity.set(0.7)
        self.player_speed.set(4)
        
    def browse_audio_file(self):
        file_path = filedialog.askopenfilename(
            title="Select a Level", 
            filetypes=(("WAV files", "*.wav"), ("All files", "*.*"))
        )        
        
        # Invalid file type
        if not file_path.endswith('.wav'):
            messagebox.showerror("Invalid Level", "Please select a .wav file.")
            return
        
        truncate_idx = file_path.find("assets/sound/")
        file_path = file_path[truncate_idx:]
        
        self.audio_path = file_path

class DisplaySpritesheetControl(tk.Frame):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, **kwargs)
        
        self.settings_panel = parent
        
        load_label = tk.Label(self, text="Active Palette Object Spritesheet", font=("Arial", 12, 'bold'))
        load_label.grid(row=0, column=0, sticky="w")
        
        self.canvas_w = 256
        self.canvas_h = 256
        self.canvas = tk.Canvas(self, width=self.canvas_w, height=self.canvas_h)
        self.canvas.grid(row=1, column=0, sticky="w")
        self.display_spritesheet()
    
    def display_spritesheet(self):
        editor = self.settings_panel.editor
        if editor.current_object not in editor.obj_name_to_spritesheet:
            return
        config_path = editor.obj_name_to_spritesheet[editor.current_object].jsonPath
        
        with open(config_path, "r") as file:
            config = json.load(file)

        # Display spritesheet
        w = config["format"]["width"]
        h = config["format"]["height"]
        scale = min(self.canvas_w / w, self.canvas_h / h)
        sprite_sheet = Image.open(config["filepath"])
        sprite_sheet = sprite_sheet.resize(
            (int(w * scale), int(h * scale)),
        )
        sprite_image_tk = ImageTk.PhotoImage(sprite_sheet)
        self.image_reference = sprite_image_tk
        self.canvas.create_image(0, 0, image=sprite_image_tk, anchor="nw")
    
class Divider(tk.Canvas):
    def __init__(self, parent):
        super().__init__(parent, height=1, width=400, bg='black')
        self.create_line(0, 1, 400, 1, fill="black", width=2) 
        
class SettingsPanel(tk.Frame):
    def __init__(self, parent, editor, **kwargs):
        super().__init__(parent, **kwargs)
        self.editor = editor
        
        self.level_width_control = LevelWidthControl(self)
        self.level_width_control.pack(anchor="w")
        
        Divider(self).pack(pady=10)
        
        self.level_upload_control = LevelUploadControl(self)
        self.level_upload_control.pack(anchor="w")
        
        Divider(self).pack(pady=10)
        
        self.upload_spritesheet_control = UploadSpritesheetControl(self)
        self.upload_spritesheet_control.pack(anchor="w")
        
        Divider(self).pack(pady=10)
        
        self.env_control = EnvControl(self)
        self.env_control.pack(anchor="w")
        
        Divider(self).pack(pady=10)
        
        self.spritesheet_control = DisplaySpritesheetControl(self)
        self.spritesheet_control.pack()
        
