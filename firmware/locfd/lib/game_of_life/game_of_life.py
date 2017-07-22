### Author: Sam Delaney
### Modified by Sebastius for the SHA2017 Badge. Fixed by polyfloyd.
### (made during prototype phase, may not work on release software)
### Description: Game of Life
### Category: Games
### License: MIT
### Appname: GoL
### Built-in: no

import badge
import ugfx
import urandom
import deepsleep
import time

def game_of_life():
    badge.eink_init()
    ugfx.init()
    ugfx.clear(ugfx.WHITE)
    ugfx.flush()
    width = 37
    height = 16
    cell_width = 8
    cell_height = 8
    grid = [[False] * height for _ in range(width)]

    def seed():
        for x in range(0, width-1):
            for y in range(0, height-1):
                if urandom.getrandbits(30) % 2 == 1:
                    grid[x][y] = True
                else:
                    grid[x][y] = False

    def display():
        for x in range(0, width):
            for y in range(0, height):
                if grid[x][y]:
                    ugfx.area(x * cell_width, y * cell_height, cell_width - 1, cell_height - 1, ugfx.BLACK)
                else:
                    ugfx.area(x * cell_width, y * cell_height, cell_width - 1, cell_height - 1, ugfx.WHITE)
        ugfx.flush()

    def alive_neighbours(x, y, wrap):
        if wrap:
            range_func = lambda dim, size: range(dim - 1, dim + 2)
        else:
            range_func = lambda dim, size: range(max(0, dim - 1), min(size, dim + 2))
        n = 0
        for nx in range_func(x, width):
            for ny in range_func(y, height):
                if grid[nx % width][ny % height]:
                    if nx != x or ny != y:
                        n += 1
        return n

    def step():
        changed = False
        new_grid = [[False] * height for _ in range(width)]
        for x in range(width):
            for y in range(height):
                neighbours = alive_neighbours(x, y, True)
                if neighbours < 2: # Starvation
                    new_grid[x][y] = False
                    changed = True
                elif neighbours > 3: # Overpopulation
                    new_grid[x][y] = False
                    changed = True
                elif not grid[x][y] and neighbours == 3: # Birth
                    new_grid[x][y] = True
                    changed = True
                else: # Survival
                    new_grid[x][y] = grid[x][y]
                    pass
        grid = new_grid
        return changed

    seed()
    generation = 0
    while True:
        generation += 1
        display()
        time.sleep(0.01)
        if not step() or generation > 50:
            seed()
            generation = 0

def reboot(wut):
  deepsleep.reboot()

ugfx.input_attach(ugfx.JOY_RIGHT, reboot)
ugfx.input_attach(ugfx.JOY_LEFT, reboot)
ugfx.input_attach(ugfx.JOY_UP, reboot)
ugfx.input_attach(ugfx.JOY_DOWN, reboot)
ugfx.input_attach(ugfx.JOY_RIGHT, reboot)
ugfx.input_attach(ugfx.BTN_A, reboot)
ugfx.input_attach(ugfx.BTN_B, reboot)
ugfx.input_attach(ugfx.BTN_START, reboot)
ugfx.input_attach(ugfx.BTN_SELECT, reboot)

game_of_life()

