import tkinter as tk
from tkinter import messagebox, filedialog, Toplevel
from PIL import Image, ImageTk
from tkinter.ttk import Combobox
import json
import os
from sprite import Spritesheet

class ObjectDetails(tk.Toplevel):
    def __init__(self, parent, editor, obj, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)
        self.obj = obj
        self.transient(parent)
        
        self.title(f"Object Details for ({obj.x}, {obj.y})")
        self.geometry("250x200")
        
        label = tk.Label(self, text=f"Object: {obj.obj_name}\nPosition: ({obj.x}, {obj.y})\nRotation: {obj.angle}°")
        label.pack(padx=20, pady=10)
        
        # settable parameters
        if "bounce_height" in self.obj.properties:
            # bounce
            label = tk.Label(self, text="Bounce Height:")
            label.pack(padx=10, pady=10)
            
            self.bounce_height_var = tk.DoubleVar()
            self.bounce_height_entry = tk.Entry(self, textvariable=self.bounce_height_var)
            self.bounce_height_var.set(self.obj.properties["bounce_height"])
            self.bounce_height_entry.pack(padx=10, pady=0)
            
            ok_button = tk.Button(self, text="OK", command=self.set_bounce)
            ok_button.pack(pady=10)
            
    def set_bounce(self):
        self.obj.properties["bounce_height"] = self.bounce_height_var.get()
        self.destroy()
