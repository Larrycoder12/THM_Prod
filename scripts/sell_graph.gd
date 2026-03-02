extends Control

const W := 32
const H := 32

@onready var graph_rect: TextureRect = $VBoxContainer/TextureRect
@onready var sell_button: Button = $Sell_mooncoin
@onready var reveal_timer: Timer = $Timer
@onready var label: Label = $VBoxContainer/Label
@onready var label2: Label = $Label2
var img: Image
var tex: ImageTexture
var price = 0

var n = 0

var prices: Array = []
var matrix: Array = []
var reveal_i = 0
var prev := 0
var revealing := false

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.

func reveal_columns(n):
	if n == 1:
		prices = generate_prices_mooncoin(5) # <-- IMPORTANT: no "var"
	else:
		prices = generate_prices_ubercoin(5)
		
	matrix = make_zero_matrix()          # <-- IMPORTANT: no "var"

	reveal_i = 0
	prev = prices[0]
	revealing = true
	

	set_from_matrix(matrix)  # optional: clear screen
	reveal_timer.start()

func _ready() -> void:
	sell_button.pressed.connect(_on_sell_pressed)
	reveal_timer.timeout.connect(_on_reveal_timer_timeout)

	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0))
	
	tex = ImageTexture.create_from_image(img)
	
	
	
	graph_rect.texture = tex
	
	reveal_columns(1)
	
	#var prices = generate_prices(4)
	#var matrix = generate_matrix(prices)
	#set_from_matrix(matrix)
		   

func set_from_matrix(matrix: Array):
	img.fill(Color(0, 0, 0))
	
	# the matrix is read sideways because it's built columns at a time
	for i in range(H):
		var col = matrix[i]
		for j in range(W):
			var r := float(col[j][0])
			var g := float(col[j][1])
			var b := float(col[j][2])
			
			#r = clamp(r, 0.0, 1.0)
			var c := Color(r, g, b, 1.0)
			
			img.set_pixel(i, W - 1- j, c)
			
	tex.update(img)

func generate_prices_mooncoin(init_price) -> Array:
	var prices: Array = []
	var fluct = rng.randi_range(1, 3)
	
	prices.append(init_price)
	
	var prev_price = init_price
	for i in range(W - 1):
		prices.append(clamp(prev_price + fluct, 1, H))
		fluct += rng.randi_range(-sqrt(i), sqrt(i + 1))
	
	return prices

func generate_prices_ubercoin(init_price) -> Array:
	var prices: Array = []
	var fluct = rng.randi_range(-1, 6)
	var crash_chance = rng.randi_range(0, 4)
	var crashed = false
	var threshold = rng.randi_range(3, 5)
	
	prices.append(init_price)
	
	var prev_price = init_price
	for i in range(W - 1):
		if not crashed:
			if (rng.randi_range(0, 120) < crash_chance or prev_price >= 31) and i > threshold:
				prices.append(0)
				crashed = true
			else:
				var price = prev_price + fluct
				prices.append(clamp(price, 1, H))
				fluct = rng.randi_range(-1, (i + 4)/2)
				prev_price = price
				if price > 21:
					crash_chance += rng.randi_range(16, 32)
				else:
					crash_chance += rng.randi_range(0, i * 2)
		else:
			prices.append(0)
	
	return prices

func generate_matrix(prices) -> Array:
	var matrix: Array = []
	var prev = prices[0]
	for i in range(H):
		var col = generate_column(prices[i], prev)
		matrix.append(col)
		
		prev = prices[i]
	#matrix.resize(H)
#
	## Create H rows, each with W zeros
	#for i in range(H):
		#var row: Array = []
		#row.resize(W)
		#row.fill(0)
		#matrix[i] = row
#
	## Place one dot per column
	#for i in range(W):
		#var j = H - (prices[i])
		#matrix[j][i] = 1

	return matrix
	
func generate_column(price, prev) -> Array:
	var col: Array = []
	for i in range(H):
		if (prev - 1 < i and i <= price - 1):
			col.append([0, 1, 0])
		elif (price - 1 <= i and i < prev - 1):
			col.append([1, 0, 0])
		elif i == price - 1:
			col.append([0.5, 0.5, 0.5])
		else:
			col.append([0, 0, 0])
	return col # it's a column, not a row. The matrix is read sideways

func make_zero_matrix() -> Array:
	var m: Array = []
	m.resize(H)
	for y in range(H):
		var row: Array = []
		for x in range(W):
			row.append([0, 0, 0])
		m[y] = row
	return m

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_reveal_timer_timeout():
	label.text = "Price: " + str(prices[reveal_i])
	if not revealing:
		return

	if reveal_i >= min(W, prices.size()):
		revealing = false
		reveal_timer.stop()
		return

	var col = generate_column(prices[reveal_i], prev)
	matrix[reveal_i] = col
	set_from_matrix(matrix)

	prev = prices[reveal_i]
	reveal_i += 1
	print(reveal_i)
	

func _on_sell_pressed() -> void:
	revealing = false
	reveal_timer.stop()

	if prices.is_empty():
		print("No prices to sell yet.")
		return

	var last_index = clamp(reveal_i - 1, 0, prices.size() - 1)
	var sell_price = prices[last_index]
	sell_mooncoin(sell_price)

func sell_mooncoin(sell_price):
	print("Sold for " + str(sell_price))
	if n == 0:
		revealing = true
		label2.text = "Selling: Ubercoin"
		reveal_columns(0)
		n += 1
	else:
		pass
	
