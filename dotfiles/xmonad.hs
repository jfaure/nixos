{-# LANGUAGE LambdaCase , ScopedTypeVariables , MultiWayIf , UnicodeSyntax #-}
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.WindowArranger
import XMonad.Layout.Reflect
import qualified XMonad.Layout.Magnifier as Magnify
import XMonad.Util.SpawnOnce
import XMonad.Util.EZConfig
import XMonad.Util.NamedActions
import XMonad.Util.Run
import XMonad.Actions.GridSelect
import XMonad.Actions.CycleWS
import XMonad.Actions.WithAll
import XMonad.Layout.ZoomRow (zoomRow, zoomIn, zoomOut, zoomReset, ZoomMessage(ZoomFullToggle))
import XMonad.Layout.Fullscreen
import XMonad.Prompt (defaultXPConfig, XPConfig(..), XPPosition(Top), Direction1D(..))
import Graphics.X11.ExtraTypes.XF86
import qualified XMonad.Layout.IndependentScreens as LIS
import qualified XMonad.StackSet as W
import qualified Data.Map as M

import XMonad.Hooks.ManageDocks

exec :: String -> X () = (\(cmd : args) -> safeSpawn cmd args) . words

myStartupHook = spawnOnce `mapM_` startupJobs

togglevga :: IO () = LIS.countScreens >>= spawn . \case
  1 -> "xrandr --output HDMI-3 --off"
  n -> "xrandr --auto --output eDP-1 --below HDMI-3"

startupJobs =
  [ "feh --bg-fill /home/jamie/Images/Wallpapers/RandLandscape.png"
  ]

main = let
  polyBar = "pkill polybar ; polybar laptop"
  polyBarFile = "/tmp/.xmonad-workspace-log"
  toggleStrutsKey XConfig{XMonad.modMask = modMask} = (modMask , xK_b)
  myPP  = let
    polybarWorkspaceClickable = \case
      x : xs -> (++ polybarWorkspaceClickable xs) $ if '0' < x && x <= '9'
        then "%{A1:xdotool key 133+" ++ x : ":}" ++ x : "%{A}"
        else [x]
      [] -> "\n"
    in def { ppOutput = appendFile polyBarFile . polybarWorkspaceClickable }
  in do 
   spawn $ "mkfifo " ++ polyBarFile
   spawn polyBar
   xmonad $ docks myConfig
     { logHook    = dynamicLogWithPP myPP
     , keys       = \c -> M.insert (toggleStrutsKey c) (sendMessage ToggleStruts) (keys myConfig c)
     }
 
myConfig = def {
    terminal = "alacritty"
--  terminal = "xfce4-terminal --hide-menubar --hide-scrollbar"
  , layoutHook = smartBorders myLayout
--, manageHook = manageDocks <+> myManageHook <+> (isFullscreen --> doFullFloat) <+> manageHook def
  , manageHook = myManageHook <+> fullscreenManageHook -- (isFullscreen --> doFullFloat) --manageDocks <+> myManageHook <+> (isFullscreen --> doFullFloat) <+> manageHook def
  , handleEventHook = fullscreenEventHook --docksEventHook <+> handleEventHook def
  , borderWidth = 0
  , modMask = mod4Mask
  , normalBorderColor = "#777777"
  , focusedBorderColor  = "#2980b9"
--, keys = \c -> myKeys c `M.union` keys def c
  , startupHook = myStartupHook
  } `additionalKeysP` myKeys myConfig

myLayout = avoidStruts $ windowArrange $ let
  tiled = let
    nmaster = 1
    ratio = 1/2  -- default proportion of screen
    delta = 0.03 -- percent of screen to increment on resize
    in Tall nmaster delta ratio
  in mkToggle (NOBORDERS ?? FULL ??  EOT) $ Magnify.magnifier (Tall 1 (3/100) (1/2)) ||| tiled ||| Mirror tiled

--windowCount  = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

---GRID SELECT
myGridConfig = let
  myColorizer = colorRangeFromClassName
    (0x31,0x2e,0x39) -- lowest inactive bg
    (0x31,0x2e,0x39) -- highest inactive bg
    (0x61,0x57,0x72) -- active bg
    (0xc0,0xa7,0x9a) -- inactive fg
    (0xff,0xff,0xff) -- active fg
  in (buildDefaultGSConfig myColorizer)
    { gs_cellheight   = 30
    , gs_cellwidth    = 200
    , gs_cellpadding  = 8
    , gs_originFractX = 0.5
    , gs_originFractY = 0.5
    }
    
spawnSelected' :: [(String, String)] -> X ()
spawnSelected' lst = gridselect defaultGSConfig lst >>= flip whenJust exec

myKeys conf = let
  spawnTerm cmd = spawn $ (XMonad.terminal conf) ++ " -e " ++ cmd
  notifyVolume = spawn "dunstify -i audio-volume-muted-blocking -t 300 -r 1000 -u normal $(pamixer --get-volume)%"
  notifyBrightness = spawn "dunstify -i audio-volume-muted-blocking -t 300 -r 1000 -u normal $(( $(brightnessctl g) * 100 / $(brightnessctl m) ))"
--nonNSP          = WSIs (return (\ws -> W.tag ws /= "nsp"))
--nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "nsp"))
-- TODO mkNamedKeyMap +
----showKeybindings :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
--  showKeybindings x = addName "Show Keybindings" $ io $ do
--    h <- spawnPipe "zenity --text-info --font=adobe courier"
--    hPutStr h (unlines $ showKm x)
--    hClose h
--    return ()

  in [
-- Xmonad
--[ ("M-C-r", spawn "xmonad --recompile")      -- Recompiles xmonad
--, ("M-S-r", spawn "xmonad --restart")        -- Restarts xmonad
--, ("M-S-q", io exitSuccess)                  -- Quits xmonad
-- Windows
--, ("M-S-c", kill1)                           -- Kill the currently focused client
--, ("M-S-a", killAll)                         -- Kill all the windows on current workspace
-- Floating windows
    ("M-<Delete>", withFocused $ windows . W.sink) -- Push floating window back to tile.
  , ("M-S-<Delete>", sinkAll)                      -- Push ALL floating windows back to tile.

  -- magnifier
  , ("M-+"    , sendMessage Magnify.MagnifyMore)
  , ("M--"    , sendMessage Magnify.MagnifyLess)
  , ("M-o"    , sendMessage Magnify.ToggleOff  )
  , ("M-S-o " , sendMessage Magnify.ToggleOn   )
  , ("M-m "   , sendMessage Magnify.Toggle     )

  -- Launch
  , ("M-g" , spawn "google-chrome-stable")
  , ("M-a" , spawnTerm "jconsole /home/jamie/j64-901-user/myprofile.ijs")
  , ("M-f" , sendMessage (Toggle FULL))
  , ("M-d" , spawn "dmenu_run -fn 'Droid Sans Mono-36'")
  , ("M-s" , spawn "cd ~/Screen-captures && sleep 0.2 && exec scrot -sf")
  , ("M-y" , spawn "i3lock --color=00000f")
  , ("M-<Return>", exec (XMonad.terminal conf))
--, ("M-t", exec "telegram-desktop")
  , ("M-t", withFocused $ windows . W.sink)
  , ("M-p", spawn "sleep 0.1 && /home/jamie/bin/figurine")
  , ("M-z", sinkAll)
  , ("M-o", spawnSelected' -- Grid Select
    [ ("Chrome", "google-chrome-stable")
    , ("Okular", "okular")
    , ("OBS", "obs-studio")
    , ("Audacity", "audacity")
    , ("Golden-Dict", "goldendict")
    , ("Ranger", "ranger")
    , ("Chessx", "chessx")
    ])

  , ("M-S-g", goToSelected  $ myGridConfig)
  , ("M-S-b", bringSelected $ myGridConfig)

  -- Windows navigation
  , ("M-m", windows W.focusMaster)  -- Move focus to the master window
  , ("M-j", windows W.focusDown)    -- Move focus to the next window
  , ("M-k", windows W.focusUp)      -- Move focus to the prev window
  , ("M-S-m", windows W.swapMaster) -- Swap the focused window and the master window
  , ("M-S-j", windows W.swapDown)   -- Swap the focused window with the next window
  , ("M-S-k", windows W.swapUp)     -- Swap the focused window with the prev window
--, ("M-<Backspace>", promote)      -- Moves focused window to master, all others maintain order
--, ("M1-S-<Tab>", rotSlavesDown)   -- Rotate all windows except master and keep focus in place
--, ("M1-C-<Tab>", rotAllDown)      -- Rotate all the windows in the current stack
--, ("M-S-s", windows copyToAll)  
--, ("M-C-s", killAllOtherCopies) 
  
  , ("M-C-M1-<Up>",   sendMessage Arrange)
  , ("M-C-M1-<Down>", sendMessage DeArrange)
--, ("M-<Up>",        sendMessage (MoveUp 10))        --  Move focused window to up
--, ("M-<Down>",      sendMessage (MoveDown 10))      --  Move focused window to down
--, ("M-<Right>",     sendMessage (MoveRight 10))     --  Move focused window to right
--, ("M-<Left>",      sendMessage (MoveLeft 10))      --  Move focused window to left
  , ("M-S-<Up>",      sendMessage (IncreaseUp 10))    --  Increase size of focused window up
  , ("M-S-<Down>",    sendMessage (IncreaseDown 10))  --  Increase size of focused window down
  , ("M-S-<Right>",   sendMessage (IncreaseRight 10)) --  Increase size of focused window right
  , ("M-S-<Left>",    sendMessage (IncreaseLeft 10))  --  Increase size of focused window left
  , ("M-C-<Up>",      sendMessage (DecreaseUp 10))    --  Decrease size of focused window up
  , ("M-C-<Down>",    sendMessage (DecreaseDown 10))  --  Decrease size of focused window down
  , ("M-C-<Right>",   sendMessage (DecreaseRight 10)) --  Decrease size of focused window right
  , ("M-C-<Left>",    sendMessage (DecreaseLeft 10))  --  Decrease size of focused window left

  -- Layouts
  , ("M-<Tab>", sendMessage NextLayout)                               -- Switch to next layout
  , ("M-S-<Space>", sendMessage ToggleStruts)                          -- Toggles struts
  , ("M-S-n", sendMessage $ Toggle NOBORDERS)                          -- Toggles noborder
  , ("M-S-=", sendMessage (Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full
--, ("M-S-f", sendMessage (Toggle "float"))
  , ("M-S-x", sendMessage $ Toggle REFLECTX)
  , ("M-S-y", sendMessage $ Toggle REFLECTY)
  , ("M-S-m", sendMessage $ Toggle MIRROR)
  , ("M-<KP_Multiply>", sendMessage (IncMasterN 1))  -- Increase clients in the master pane
  , ("M-<KP_Divide>", sendMessage (IncMasterN (-1))) -- Decrease clients in the master pane
--, ("M-S-<KP_Multiply>", increaseLimit)             -- Increase windows that can be shown
--, ("M-S-<KP_Divide>", decreaseLimit)               -- Decrease windows that can be shown

  , ("M-h", sendMessage Shrink)
  , ("M-l", sendMessage Expand)
--, ("M-C-j", sendMessage MirrorShrink)
--, ("M-C-k", sendMessage MirrorExpand)
  , ("M-S-;", sendMessage zoomReset)
  , ("M-;", sendMessage ZoomFullToggle)
  -- Workspaces
  , ("M-.", nextScreen)                           -- Switch focus to next monitor
  , ("M-,", prevScreen)                           -- Switch focus to prev monitor
--, ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)      -- Shifts focused window to next workspace
--, ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP) -- Shifts focused window to previous workspace

  , ("<XF86AudioRaiseVolume>" , exec "pactl set-sink-volume @DEFAULT_SINK@ +1.5%" *> notifyVolume)
  , ("<XF86AudioLowerVolume>" , exec "pactl set-sink-volume @DEFAULT_SINK@ -1.5%" *> notifyVolume)
  , ("<XF86AudioMute>"        , exec "pactl set-sink-mute @DEFAULT_SINK@ toggle")    
  , ("<XF86AudioPlay>"        , exec "playerctl play-pause")    
  , ("<XF86AudioPrev>"        , exec "playerctl previous")    
  , ("<XF86AudioNext>"        , exec "playerctl next")    
  , ("<XF86MonBrightnessUp>"  , exec "brightnessctl s 1%+" *> notifyBrightness)
  , ("<XF86MonBrightnessDown>", exec "brightnessctl s 1%-" *> notifyBrightness)
  , ("<XF86KbdBrightnessUp>"  , exec "brightnessctl --device=smc::kbd_backlight s 10%+")
  , ("<XF86KbdBrightnessDown>", exec "brightnessctl --device=smc::kbd_backlight s 10%-")
  , ("<XF86Eject>"            , exec "toggleeject")
  , ("<XF86LaunchA>"          , goToSelected  $ myGridConfig)
  , ("<XF86LaunchB>"          , bringSelected $ myGridConfig)
  , ("<Print>"                , exec "scrotd 0")
  ] ++ [ (otherModMasks ++ "M-" ++ [key], action tag)
       | (tag, key)  <- ((\x -> ([x],x)) <$> "123456789")
       , (otherModMasks, action) <- [ ("", windows . W.greedyView {-W.view-})
                                    , ("S-", windows . W.shift)]
       ]


myManageHook = let
  role = stringProperty "WM_WINDOW_ROLE"
  in composeAll
  [ className =? "feh"    --> doFloat
  , role      =? "pop-up" --> doFloat
  ] <+> composeOne [ isFullscreen -?> doFullFloat ]

-- myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats $ 
--              mkToggle (NBFULL ?? NOBORDERS ?? EOT) $ myDefaultLayout
--            where 
--                myDefaultLayout = tall ||| grid ||| threeCol ||| threeRow ||| oneBig ||| noBorders monocle ||| space ||| floats
-- 
-- 
-- tall       = renamed [Replace "tall"]     $ limitWindows 12 $ spacing 6 $ ResizableTall 1 (3/100) (1/2) []
-- grid       = renamed [Replace "grid"]     $ limitWindows 12 $ spacing 6 $ mkToggle (single MIRROR) $ Grid (16/10)
-- threeCol   = renamed [Replace "threeCol"] $ limitWindows 3  $ ThreeCol 1 (3/100) (1/2) 
-- threeRow   = renamed [Replace "threeRow"] $ limitWindows 3  $ Mirror $ mkToggle (single MIRROR) zoomRow
-- oneBig     = renamed [Replace "oneBig"]   $ limitWindows 6  $ Mirror $ mkToggle (single MIRROR) $ mkToggle (single REFLECTX) $ mkToggle (single REFLECTY) $ OneBig (5/9) (8/12)
-- monocle    = renamed [Replace "monocle"]  $ limitWindows 20 $ Full
-- space      = renamed [Replace "space"]    $ limitWindows 4  $ spacing 12 $ Mirror $ mkToggle (single MIRROR) $ mkToggle (single REFLECTX) $ mkToggle (single REFLECTY) $ OneBig (2/3) (2/3)
-- floats     = renamed [Replace "floats"]   $ limitWindows 20 $ simplestFloat
