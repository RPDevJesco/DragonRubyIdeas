def tick(args)
    setup(args)
    update_player(args)
    update_enemy(args)
    render(args)
  end
  
  def setup(args)
    args.state.player ||= { x: 640, y: 100, w: 32, h: 32, speed: 5 }
    args.state.enemy ||= { x: 500, y: 100, w: 32, h: 32, speed: 2, patrol_range: [400, 600], state: :patrolling }
  end
  
  def update_enemy(args)
    enemy = args.state.enemy
    player = args.state.player
  
    case enemy[:state]
    when :patrolling
      # Move left or right within patrol range
      if enemy[:x] <= enemy[:patrol_range][0]
        enemy[:speed] = enemy[:speed].abs
      elsif enemy[:x] >= enemy[:patrol_range][1]
        enemy[:speed] = -enemy[:speed].abs
      end
      enemy[:x] += enemy[:speed]
  
      # If player is close, switch to chasing
      if (enemy[:x] - player[:x]).abs < 100
        enemy[:state] = :chasing
      end
  
    when :chasing
      # Move toward the player
      enemy[:speed] = 3
      enemy[:x] += enemy[:speed] if enemy[:x] < player[:x]
      enemy[:x] -= enemy[:speed] if enemy[:x] > player[:x]
  
      # If player is close enough, attack
      if (enemy[:x] - player[:x]).abs < 10
        enemy[:state] = :attacking
      elsif (enemy[:x] - player[:x]).abs > 200
        enemy[:state] = :patrolling
      end
  
    when :attacking
      # Reset enemy state after a short delay
      enemy[:state] = :patrolling if args.state.tick_count % 60 == 0
    end
  end
  
  def update_player(args)
    player = args.state.player
  
    if args.inputs.keyboard.left
      player[:x] -= player[:speed]
    elsif args.inputs.keyboard.right
      player[:x] += player[:speed]
    end
  end
  
  def render(args)
    args.outputs.solids << [args.state.player[:x], args.state.player[:y], 32, 32, 0, 255, 0] # Green player
    args.outputs.solids << [args.state.enemy[:x], args.state.enemy[:y], 32, 32, 255, 0, 0] # Red enemy
  end
