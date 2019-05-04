#[
## sap.nim | Summer AI Project
## https://github.com/davidgarland/sap
]#

#   1000    Screen Dimensions
# *------*
# |      |
# |      | 1000
# |      |
# *------*
# 
#  100   Physics
# *----*
# |    | 100
# |    |
# *----*

import
  strformat,
  random

import
  arraymancer,
  sdl2/gfx,
  sdl2,
  sol

import
  core/game

#[
## NN Settings
]#

const TrainSet = 100_000 # Must be batches^2.
const Batches = 100
const Rate = 0.0000001'f32 # add 1 zero??
const Epochs = 2500

#[
## Game Settings
]#

const PhysicsFactor = 100 # Physics = 100x NN
const ScreenFactor = 10   # Screen = 10x Physics
const ScreenSize = (1000, 1000)
const G = 9.81

#[
## Helper Functions
]#

func findAngle*(x: float32, v: float32): float32 =
  let v2 = v * v
  let v4 = v2 * v * v
  let numer = v2 + sqrt(v4 - G*(G*(x*x)))
  let denom = G*x
  result = arctan(numer / denom)

#[
## Main Program
]#

proc main =
  randomize()

  # NN Setup

  let ctx = newContext Tensor[float32]

  var
    xt = ctx.variable newTensor[float32](TrainSet, 2)
    yt = newTensor[float32](TrainSet, 1)

  for i in 0 ..< TrainSet:
    let d = rand(100.0'f32) # Distance
    let v = 32'f32 # Velocity
    xt.value[i, 0] = d # / (PhysicsFactor * PhysicsFactor) # because desmos
    xt.value[i, 1] = v # / PhysicsFactor
    yt[i, 0] = findAngle(xt.value[i, 0], xt.value[i, 1]) # / 2

  network ctx, Shooter:
    layers:
      fc1: Linear(2, 8)
      hd1: Linear(8, 8)
      hd2: Linear(8, 16)
      hd3: Linear(16, 8)
      fc2: Linear(8, 1)
    forward x:
      x.fc1.hd1.relu.hd2.relu.hd3.fc2

  # NN Training

  let mdl = ctx.init(Shooter)
  let opt = mdl.optimizerSGD(learning_rate = Rate)

  for epoch in 0 ..< Epochs:
    for batch in 0 ..< Batches:
      let offset = ((batch * TrainSet).float / Batches.float).int
      let x = xt[offset ..< offset + Batches, _]
      let y = yt[offset ..< offset + Batches, _]

      let outp = mdl.forward(x)
      let loss = mse_loss(outp, y) # mse > cross_entropy for non-classification

      if batch mod 20 < 1:
        echo "[" & $epoch & ";" & $batch & "] Loss: " & $loss.value.data[0]
      loss.backprop
      opt.update

  # Game Setup

  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 Initialization Failed"
  defer: sdl2.quit()

  var game = newGame("Summer AI Project", ScreenSize, ts = 1, tps = 24)
  var target, projectile, velocity: float32x2

  # Game Procedures

  proc in_bounds: bool =
    if projectile.x > 100 or projectile.x < 0:
      return false
    elif projectile.y > 100 or projectile.y < 0:
      return false
    return true

  proc tick =
    velocity.y = velocity.y - (G / game.tps.float32) # TODO: add `y-=` and such to Sol.
    projectile = projectile + (velocity / game.tps.float32)
    game.takeInput
    game.wait

  proc show =
    game.renderer.setDrawColor(110, 132, 174)
    game.renderer.clear
    game.renderer.filledCircleColor((target.x * ScreenFactor).int16,
      game.getY(target.y * ScreenFactor).int16, 10, 0xff00ffff'u32)
    game.renderer.filledCircleColor((projectile.x * ScreenFactor).int16,
      game.getY(projectile.y * ScreenFactor).int16, 10, 0xff00ffff'u32)
    game.renderer.present

  # Game Runtime

  while not game.inputs[Input.Quit]:
    let d = rand(100'f32).float32
    let v = 32.0.float32
    target = f32x2(d, 0.0'f32)
    velocity = f32x2(32'f32, 0'f32)
    projectile = f32x2(0'f32, 0'f32)
    # AI Stuff
    let rad = mdl.forward(ctx.variable([[d,v]].toTensor)).value.data[0]
    velocity = velocity.rot(rad)
    while not game.inputs[Input.Quit] and in_bounds():
      show()
      tick()
    let diff = abs(projectile.x - target.x)
    echo diff

main()
