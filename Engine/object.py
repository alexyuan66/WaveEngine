class Object:
    def __init__(self, x, y, obj_name, angle):
        self.x = x
        self.y = y
        self.obj_name = obj_name
        self.angle = angle
        self.properties = {}
        
        if self.obj_name == "Bouncer":
            self.properties["bounce_height"] = 18.5
        
    def serialized(self):
        res = {
            "x": self.x + 5,
            "y": 9 - self.y,
            "obj_name": self.obj_name,
            "angle": self.angle // 90
        }
        res.update(self.properties)
        return res
