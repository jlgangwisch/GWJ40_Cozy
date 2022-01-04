#noise shaders come from https://docs.godotengine.org/en/stable/tutorials/shading/your_first_shader/your_second_spatial_shader.html


extends StaticBody

export var size := 64

var noise = OpenSimplexNoise.new()
var noise_text : NoiseTexture = NoiseTexture.new()
var noise_array := PoolRealArray()

var offset := Vector2(0,0)
var heightmap_image: Image = Image.new()
var heightmap_shape := HeightMapShape.new()
var material : Material
var height_scalor :=10


onready var mesh_instance : MeshInstance = $WaterMesh
onready var collision_shape : CollisionShape = $CollisionShape

func _ready()->void:
	
		#setup noiseTexture
	noise_text.set_width(size)
	noise_text.set_height(size)
	noise_text.set_noise(noise)
	
	#setup collision heightmap
	heightmap_shape.map_width = size
	heightmap_shape.map_depth = size
	noise_array.resize(size*size)
	collision_shape.shape = heightmap_shape
	
	#to align with collision shape the size should be -1 and the subdivisions -2
	mesh_instance.mesh.set_size(Vector2(size-1, size-1))
	mesh_instance.mesh.set_subdivide_depth(size-2)
	mesh_instance.mesh.set_subdivide_width(size-2)
	
	#set shader param for heigh scaling texture read
	material = mesh_instance.mesh.material
	material.set_shader_param("size", size)
	material.set_shader_param("height_scale", height_scalor)
	
func _physics_process(delta: float) -> void:
	#update time sync
	var fix_time  := OS.get_ticks_msec() - floor(OS.get_ticks_msec()/3600)*3600
	material.set_shader_param("outside_time", fix_time)
	
	#update noise texture
	#offset += Vector2(1,0)
	noise_text.set_noise_offset(offset)
	
	#update mesh shader noise texture
	material.set_shader_param("noise", noise_text)
	
	#update collider heightmap
	#yield(noise_text, "changed")
	heightmap_image = noise_text.get_data()
	if heightmap_image != null:
		heightmap_image.lock()
		var i := 0
		for y in size:
			for x in size:
				#noise_array[i] = heightmap_image.get_pixel(x,y).r * height_scalor
				noise_array[i] = height_simple(Vector2(x,y), fix_time) * height_scalor
				i += 1
		heightmap_image.unlock()
		collision_shape.shape.map_data = noise_array
		print (fix_time)
	else:
		print("null")

func height_simple(position: Vector2, time: float) -> float:
	var offset : Vector2 = Vector2(0.01 * cos(position.x + time), 0.01 * cos(position.y + time))
	return heightmap_image.get_pixelv(position - offset*size).r
	
func wave (position : Vector2) -> float:
	var noise_read : float = heightmap_image.get_pixel(position.x,position.y).r * 2.0 -1.0
	position += Vector2(noise_read, noise_read)
	var w : float = 1.0 - abs(sin(position.x))
	var v : float = 1.0 - abs(sin(position.y))
	return pow(1.0 - pow(w*v, 0.65), 4.0)

func height (position : Vector2, t : float) -> float:

	var d : float = wave(Vector2(position.x + t, position.y + t) * 0.4) * 0.3
	d += wave(Vector2(position.x - t, position.y - t) * 0.3) * 0.3
	d += wave(Vector2(position.x + t, position.y + t) * 0.5) * 0.2
	d += wave(Vector2(position.x - t, position.y - t) * 0.6) * 0.2
	return d*height_scalor
