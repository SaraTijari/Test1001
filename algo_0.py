while get_x() != get_target_x():
    if get_x() < get_target_x():
        while get_direction() != EAST:
            turn_left()
    else:
        while get_direction() != WEST:
            turn_left()
    while is_in_front_of_enemy() or not can_move():
        turn_left()
        if can_move():
            move()
            turn_right()
    move()

while get_y() != get_target_y():
    if get_y() < get_target_y():
        while get_direction() != SOUTH:
            turn_left()
    else:
        while get_direction() != NORTH:
            turn_left()
    while is_in_front_of_enemy() or not can_move():
        turn_right()
        if can_move():
            move()
            turn_left()
    move()

destroy_dark_force()