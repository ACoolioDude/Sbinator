#if (!macro)

// Important
import data.Player;
import data.backend.Discord.DiscordClient;
import data.backend.GameUtils.EngineConfiguration;
import data.backend.GameUtils.DataHandler;
import data.backend.GameUtils.Paths;
import data.backend.FramePerSecond;
import data.backend.HiddenProcess;
#if linux
import data.backend.linux.DEDetector;
#end
import transition.Transition;
import transition.StateHandler;
import transition.SubstateHandler;

// States
import states.InitState;
import states.game.PlayState;
import states.menus.CreditsMenu;
import states.menus.TitleScreen;
import states.modules.CrashState;

// Substates
import substates.game.GameOver;
import substates.game.PauseMenu;
import substates.menus.PopUp.PopUpEvent;
import substates.options.OptionsMenu;

// Other
#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end
#end
