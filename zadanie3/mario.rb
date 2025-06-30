require 'ruby2d'

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
TILE_SIZE = 40
GRAVITY = 1
JUMP_FORCE = -15
MAX_FALL_SPEED = 20

score = 0
lives = 3

enemies = []
coins = []
obstacles = []
holes = []

set title: 'Simple Mario', width: WINDOW_WIDTH, height: WINDOW_HEIGHT
set background: 'skyblue'

player = Rectangle.new(
  x: 100, y: WINDOW_HEIGHT - TILE_SIZE * 2,
  width: TILE_SIZE, height: TILE_SIZE,
  color: 'blue'
)
player_velocity = { x: 0, y: 0 }
on_ground = false

score_text = Text.new("Score: #{score}", x: 10, y: 10, size: 20, color: 'white')
lives_text = Text.new("Lives: #{lives}", x: 10, y: 40, size: 20, color: 'white')

def generate_level
  tiles_count = (WINDOW_WIDTH / TILE_SIZE) * 3
  level_tiles = []
  i = 0
  while i < tiles_count
    r = rand
    if r < 0.1
      hole_length = [2,3,4].sample
      hole_length.times { level_tiles << :hole }
      i += hole_length
    elsif r < 0.2
      level_tiles << :obstacle
      i += 1
    else
      level_tiles << :ground
      i += 1
    end
  end
  level_tiles
end

level = generate_level

level.each_with_index do |tile, i|
  x = i * TILE_SIZE
  case tile
  when :ground
    Rectangle.new(x: x, y: WINDOW_HEIGHT - TILE_SIZE, width: TILE_SIZE, height: TILE_SIZE, color: 'green')
  when :obstacle
    obstacles << Rectangle.new(x: x, y: WINDOW_HEIGHT - TILE_SIZE * 2, width: TILE_SIZE, height: TILE_SIZE, color: 'brown')
    Rectangle.new(x: x, y: WINDOW_HEIGHT - TILE_SIZE, width: TILE_SIZE, height: TILE_SIZE, color: 'green')
  when :hole
    holes << [x, WINDOW_HEIGHT - TILE_SIZE]
  end

  if tile == :ground && rand < 0.1
    c = Rectangle.new(
      x: x + TILE_SIZE/4, y: WINDOW_HEIGHT - TILE_SIZE * 2 + TILE_SIZE/4,
      width: TILE_SIZE/2, height: TILE_SIZE/2,
      color: 'yellow'
    )
    coins << c
  end
end

ground_positions = level.each_with_index.select { |t,i| t == :ground }.map(&:last)
spawn_positions = ground_positions.select { |i| i > (WINDOW_WIDTH / TILE_SIZE) }
spawn_positions = ground_positions if spawn_positions.empty?
enemy_positions = spawn_positions.sample(5)
enemy_positions.each do |i|
  x = i * TILE_SIZE
  e = Rectangle.new(x: x, y: WINDOW_HEIGHT - TILE_SIZE * 2, width: TILE_SIZE, height: TILE_SIZE, color: 'red')
  dir = x > WINDOW_WIDTH ? -2 : [-2, 2].sample
  enemies << { obj: e, dir: dir }
end

on :key_down do |event|
  case event.key
  when 'left'  then player_velocity[:x] = -5
  when 'right' then player_velocity[:x] = 5
  when 'up'
    if on_ground
      player_velocity[:y] = JUMP_FORCE
      on_ground = false
    end
  end
end

on :key_up do |event|
  case event.key
  when 'left', 'right' then player_velocity[:x] = 0
  end
end

update do
  player_velocity[:y] += GRAVITY
  player_velocity[:y] = MAX_FALL_SPEED if player_velocity[:y] > MAX_FALL_SPEED

  player.x += player_velocity[:x]
  player.y += player_velocity[:y]

  if player.y + TILE_SIZE >= WINDOW_HEIGHT - TILE_SIZE
    player.y = WINDOW_HEIGHT - TILE_SIZE * 2
    player_velocity[:y] = 0
    on_ground = true
  else
    on_ground = false
  end

  holes.each do |hx, hy|
    if player.x.between?(hx, hx + TILE_SIZE - player.width) && player.y + TILE_SIZE >= hy
      lives -= 1
      lives_text.text = "Lives: #{lives}"
      player.x, player.y = 100, WINDOW_HEIGHT - TILE_SIZE * 2
      player_velocity = { x: 0, y: 1 }
    end
  end

  obstacles.each do |obs|
    if player.contains?(obs.x + 1, obs.y + 1)
      player.x -= player_velocity[:x]
    end
  end

  coins.reject! do |coin|
    if player.contains?(coin.x, coin.y)
      score += 10
      score_text.text = "Score: #{score}"
      coin.remove
      true
    else
      false
    end
  end

  enemies.each do |e|
    obj = e[:obj]
    obj.x += e[:dir]
    if obj.x < 0 || obj.x + TILE_SIZE > level.size * TILE_SIZE
      e[:dir] *= -1
    end
    if player.contains?(obj.x, obj.y) || player.contains?(obj.x + TILE_SIZE, obj.y + TILE_SIZE)
      if player_velocity[:y] > 0
        obj.remove
        enemies.delete(e)
        score += 50
        score_text.text = "Score: #{score}"
        player_velocity[:y] = JUMP_FORCE / 2
      else
        lives -= 1
        lives_text.text = "Lives: #{lives}"
        player.x, player.y = 100, WINDOW_HEIGHT - TILE_SIZE * 2
        player_velocity = { x: 0, y: 0 }
      end
    end
  end

  if lives <= 0
    Text.new("Game Over", x: WINDOW_WIDTH/2 - 100, y: WINDOW_HEIGHT/2, size: 50, color: 'white')
    close
  end
end

show
