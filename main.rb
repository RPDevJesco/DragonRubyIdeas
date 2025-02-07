def tick(args)
  setup(args)
  handle_input(args)
  update_bullets(args)
  update_enemy(args)
  check_collisions(args)
  render(args)
end

def setup(args)
  args.state.boss ||= { x: 640, y: 360, speed: 5, fire_cooldown: 0 }
  args.state.enemy ||= { x: 640, y: 100, speed: 4, dodging: false }
  args.state.bullets ||= []
end

def handle_input(args)
  boss = args.state.boss
  speed = boss[:speed]

  boss[:x] -= speed if args.inputs.keyboard.left
  boss[:x] += speed if args.inputs.keyboard.right
  boss[:y] += speed if args.inputs.keyboard.up
  boss[:y] -= speed if args.inputs.keyboard.down

  # Fire bullets when pressing SPACE
  if args.inputs.keyboard.key_down.one && boss[:fire_cooldown] <= 0
    fire_bullets(args, boss[:bullet_type] || :crossfire)
    boss[:fire_cooldown] = 30
  end
  if args.inputs.keyboard.key_down.two && boss[:fire_cooldown] <= 0
    fire_bullets(args, boss[:bullet_type] || :wave)
    boss[:fire_cooldown] = 30
  end
  if args.inputs.keyboard.key_down.three && boss[:fire_cooldown] <= 0
    fire_bullets(args, boss[:bullet_type] || :radial)
    boss[:fire_cooldown] = 30
  end

  boss[:fire_cooldown] -= 1 if boss[:fire_cooldown] > 0
end

def fire_bullets(args, pattern)
  boss = args.state.boss
  case pattern
  when :crossfire
    fire_crossfire(args, boss)
  when :wave
    fire_wave(args, boss)
  when :radial
    fire_radial(args, boss)
  end
end

def fire_spiral(args, boss)
  num_bullets = 12
  args.state.spiral_angle ||= 0
  args.state.spiral_angle += 10

  num_bullets.times do |i|
    angle = (360 / num_bullets) * i + args.state.spiral_angle
    rad = angle * Math::PI / 180

    args.state.bullets << {
      x: boss[:x],
      y: boss[:y],
      dx: Math.cos(rad) * 4,
      dy: Math.sin(rad) * 4,
      lifetime: 180,
      type: :spiral
    }
  end
end

def fire_crossfire(args, boss)
  directions = [
    [1, 0],  [-1, 0],  # Left/Right
    [0, 1],  [0, -1],  # Up/Down
    [1, 1],  [-1, -1], # Diagonal Right-Down, Left-Up
    [1, -1], [-1, 1]   # Diagonal Right-Up, Left-Down
  ]

  directions.each do |dir|
    args.state.bullets << {
      x: boss[:x],
      y: boss[:y],
      dx: dir[0] * 5,  # Bullet speed
      dy: dir[1] * 5,
      lifetime: 180,
      type: :crossfire
    }
  end
end

def fire_wave(args, boss)
  num_bullets = 6

  num_bullets.times do |i|
    angle = (360 / num_bullets) * i
    rad = angle * Math::PI / 180

    args.state.bullets << {
      x: boss[:x],
      y: boss[:y],
      dx: Math.cos(rad) * 5,
      dy: Math.sin(rad) * 5,
      lifetime: 180,
      type: :wave,
      wave_offset: i * 10
    }
  end
end

def fire_radial(args, boss)
  num_bullets = 16

  num_bullets.times do |i|
    angle = (360 / num_bullets) * i
    rad = angle * Math::PI / 180

    args.state.bullets << {
      x: boss[:x],
      y: boss[:y],
      dx: Math.cos(rad) * 6,
      dy: Math.sin(rad) * 6,
      lifetime: 180,
      type: :radial
    }
  end
end

def update_bullets(args)
  args.state.bullets.reject! { |b| b[:lifetime] <= 0 }

  args.state.bullets.each do |bullet|
    bullet[:x] += bullet[:dx]
    bullet[:y] += bullet[:dy]

    # Apply special movement patterns based on bullet type
    case bullet[:type]
    when :wave
      bullet[:y] += Math.sin((args.state.tick_count + bullet[:wave_offset]) * 0.1) * 3
    when :spiral
      bullet[:dx] *= 1.01 # Slight acceleration outward
      bullet[:dy] *= 1.01
    end

    bullet[:lifetime] -= 1
  end
end

def update_enemy(args)
  enemy = args.state.enemy
  bullets = args.state.bullets

  # Default random movement
  enemy[:x] += ((rand * 4 - 2) * enemy[:speed]) # Generates -2 to 2

  # Check for nearby bullets
  close_bullets = bullets.select { |b| (b[:x] - enemy[:x]).abs < 50 && (b[:y] - enemy[:y]).abs < 50 }
  
  unless close_bullets.empty?
    enemy[:x] += enemy[:speed] * ((rand < 0.5) ? -1 : 1) # Dodge randomly left or right
  end

  # Keep enemy within screen bounds
  enemy[:x] = enemy[:x].clamp(50, 1230)
end

def check_collisions(args)
  enemy = args.state.enemy
  bullets = args.state.bullets

  bullets.each do |bullet|
    if (bullet[:x] - enemy[:x]).abs < 15 && (bullet[:y] - enemy[:y]).abs < 15
      enemy[:hit_count] ||= 0
      enemy[:hit_count] += 1
      bullet[:lifetime] = 0 # Remove bullet on hit

      if enemy[:hit_count] >= 5
        args.state.game_over = true
      end
    end
  end
end

def render(args)
  # Draw boss
  args.outputs.solids << [args.state.boss[:x] - 16, args.state.boss[:y] - 16, 32, 32, 0, 0, 255]

  # Draw enemy
  args.outputs.solids << [args.state.enemy[:x] - 16, args.state.enemy[:y] - 16, 32, 32, 255, 0, 0]

  # Draw bullets
  args.state.bullets.each do |bullet|
    args.outputs.solids << [bullet[:x], bullet[:y], 8, 8, 255, 255, 0]
  end

  # Display win message
  if args.state.game_over
    args.outputs.labels << [540, 360, "YOU WIN!"]
  end
endg
