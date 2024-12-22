import tkinter as tk
from tkinter import messagebox, filedialog
from PIL import Image, ImageTk
from tkinter.ttk import Combobox
import json
import os
from sprite import Spritesheet

class UtilPanel(tk.Frame):
    def __init__(self, parent, editor, **kwargs):
        super().__init__(parent, **kwargs)
        self.editor = editor
        
        # Rotation Control
        rotation_label = tk.Label(self, text="Rotation", font=("Arial", 12, "bold"), bg="#f0f0f0")
        rotation_label.grid(row=0, column=0)
        
        rotation_options = [0, 90, 180, 270]
        rotation_dropdown = tk.OptionMenu(self, self.editor.rotation_angle, *rotation_options)
        rotation_dropdown.config(bg="#f0f0f0", font=("Arial", 10), highlightthickness=0)
        rotation_dropdown.grid(row=0, column=1, padx=10, pady=5)
        
        # Erase grid button
        erase_button = tk.Button(self, text="Erase Grid", command=self.editor.erase_grid, font=("Arial", 12, "bold"))
        erase_button.grid(row = 0, column=2, padx=10, pady=5)

        # Generate button should now be placed inside the palette_frame as well
        generate_button = tk.Button(self, text="Generate Level", command=self.generate_json, 
                                    font=("Arial", 12, "bold"), bg="#f0f0f0")
        generate_button.grid(row=0, column=3, padx=10, pady=5)
        
    def generate_json(self):
        if self.editor.flag_count != 1:
            messagebox.showerror("Error", f"You have {self.editor.flag_count} flags. Levels must have exactly 1 flag tile.")
            return

        payload = {}
        payload["config"] = {
            "gravity": self.editor.settings_panel.env_control.gravity.get(), #def: 0.7
            "player_speed": self.editor.settings_panel.env_control.player_speed.get(), #def = 4
            "cell_size": 48,
            "level_width": self.editor.grid_size_x,
            "audio": self.editor.settings_panel.env_control.audio_path,
            "sprite_map": {obj_name: self.editor.obj_name_to_spritesheet[obj_name].jsonPath for obj_name in self.editor.obj_name_to_spritesheet.keys()}
        }
        payload["objects"] = [obj.serialized() for obj in self.editor.grid_objects.values()]

        with open("assets/levels/custom_level.json", "w") as file:
            json.dump(payload, file, indent=4)
        messagebox.showinfo("Success", "Your level has been created. It is titled 'custom_level.json'")
