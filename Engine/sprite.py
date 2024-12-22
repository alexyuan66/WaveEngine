import json
from PIL import Image, ImageTk

class Frame:
    def __init__(self, frame_num, image_lst):
        self.frame_num = frame_num
        self.image_lst = image_lst #Frames rotated from 0 to 90 to 180 to 270
        
    def get_frame(self, angle):
        return self.image_lst[int(angle // 90)]

class Spritesheet:
    def __init__(self, obj_name, jsonPath, cell_size):
        self.obj_name = obj_name
        self.jsonPath = jsonPath
        self.sprite_sheet = [] #list of frames
        self.cell_size = cell_size
        self.load_sprite_sheet(self.jsonPath)

        
    def update_sprite_sheet(self, config_path):
        self.jsonPath = config_path
        self.load_sprite_sheet(self.jsonPath)
        
    def load_sprite_sheet(self, config_path):
        with open(config_path, "r") as file:
            config = json.load(file)

        sprite_sheet = Image.open(config["filepath"])
        tile_width, tile_height = config["format"]["tileWidth"], config["format"]["tileHeight"]
        width, height = config["format"]['width'], config["format"]['height']
        
        rows = height // tile_height
        cols = width // tile_width

        # Add frames
        frame_num = 0
        for r in range(rows):
            for c in range(cols):
                new_frame = Frame(frame_num, [self.load_frame(sprite_sheet, r, c, tile_width, tile_height, angle) for angle in [0, 90, 180, 270]])
                self.sprite_sheet.append(new_frame)
                frame_num += 1
    
    def load_frame(self, sprite_sheet, row, col, tile_width, tile_height, angle):
        left, upper = col * tile_width, row * tile_height
        cropped_image = sprite_sheet.crop((left, upper, left + tile_width, upper + tile_height))
        cropped_image = cropped_image.resize((self.cell_size, self.cell_size)).rotate(360 - angle, expand=True)
        return ImageTk.PhotoImage(cropped_image)
    
    def get_sprite(self, frame_num, angle):
        return self.sprite_sheet[frame_num].get_frame(angle)
