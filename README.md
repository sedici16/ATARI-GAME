# Atari 2600 Game: Jet vs. Bomber

This project is an **Atari 2600 game** built in 6502 assembly language. The game involves a jet controlled by the player and a bomber as an enemy. It includes gameplay mechanics like movement, collision detection, score tracking, and random enemy behavior.

## Features

### Gameplay
- **Player Control**: Navigate the jet using the joystick.
- **Enemy Behavior**: The bomber moves with randomized positions.
- **Collision Detection**: Game detects player-bomber and player-playfield collisions.
- **Scoreboard**: Displays the player's score and a timer in BCD format.

### Visuals
- Sprites for jet and bomber with frame animation.
- Color variations using TIA registers.
- Playfield designs for background decoration.

### Mechanics
- **Random Enemy Movement**: Implements a Linear Feedback Shift Register (LFSR) for generating random numbers.
- **Fine Positioning**: Adjusts sprites with sub-pixel accuracy.
- **Digit Display**: BCD conversion for rendering score and timer.

## Project Structure

- **Constants and Variables**: Defined for positions, scores, timers, and pointers.
- **Subroutines**:
  - `SetObjectSubRoutine`: Handles fine positioning.
  - `bomber_random_num`: Generates random numbers for enemy movement.
  - `calculate_digit_offset`: Converts BCD values for score and timer display.
  - `gameover`: Handles the game-over sequence.
- **Graphics Data**:
  - `jet_Frame0` and `jet_Frame1`: Frames for the player's jet.
  - `bomber_Frame0`: Frame for the bomber sprite.
  - `Digits`: Sprite data for numbers used in score and timer.

## Compilation

Compile the game using the **DASM assembler**:
```bash
dasm cart_exercises3.asm -f3 -v0 -ocart_exercises2.bin


ATARI%20GAME
=====

[Open this project in 8bitworkshop](http://8bitworkshop.com/redir.html?platform=vcs&githubURL=https%3A%2F%2Fgithub.com%2Fsedici16%2FATARI-GAME&file=hello.a).
