import
  posix,
  math,
  os

import
  arraymancer,
  sdl2,
  sol

type
  SDLException* = object of Exception

template sdlFailIf*(cond: typed; reason: string) =
  if cond:
    raise SDLException.newException(reason & ", SDL Error: " & $getError())

type
  Input* {.pure.} = enum
    None, Reset, Quit, ScaleUp, ScaleDown
  Game* = ref object
    inputs*: array[Input, bool]
    window*: WindowPtr
    renderer*: RendererPtr
    res*: (int, int)
    tps*: int
    ts*: float

proc newGame*(name: string; res: (int, int); tps: int = 60; ts: float = 1): Game =
  new result
  result.window = createWindow(title = name,
  x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED,
  w = res[0].cint, h = res[1].cint, flags = SDL_WINDOW_SHOWN.uint32)
  sdlFailIf result.window.isNil: "Window could not be created"
  result.renderer = result.window.createRenderer(index = -1,
  flags = Renderer_Accelerated or Renderer_PresentVsync)
  sdlFailIf result.renderer.isNil: "Renderer could not be created"
  result.res = res
  result.tps = tps
  result.ts = ts

proc toInput*(s: Scancode): Input =
  case s:
  of SDL_SCANCODE_R: Input.Reset
  of SDL_SCANCODE_Q: Input.Quit
  of SDL_SCANCODE_W: Input.ScaleUp
  of SDL_SCANCODE_S: Input.ScaleDown
  else: Input.None

proc takeInput*(g: Game) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind:
    of QuitEvent: g.inputs[Input.Quit] = true
    of KeyDown:   g.inputs[event.key.keysym.scancode.toInput] = true
    of KeyUp:     g.inputs[event.key.keysym.scancode.toInput] = false
    else: discard
  if g.inputs[Input.ScaleUp]:
    g.ts = (g.ts + 0.1).round(places = 2)
    echo "TIMESCALE: " & $g.ts
  if g.inputs[Input.ScaleDown]:
    g.ts = (g.ts - 0.1).round(places = 2)
    echo "TIMESCALE: " & $g.ts

proc wait*(g: Game) =
  discard
  #let time = max((1000.0 / g.tps.float / g.ts), 1).uint32
  #if time > 1'u32:
  #  for i in 0 ..< time:
  #    pumpEvents()
  #    delay(1)

proc getY*[T](g: Game; y: T): int16 =
  result = -y.int16 + g.res[1].int16
