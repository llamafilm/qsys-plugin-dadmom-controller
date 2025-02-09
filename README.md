# DadMom Controller

This is a Q-Sys plugin for the Monitor Operating Module. Unaffiliated with Digital Audio Denmark.

Communicates with the DadMom controller via unicast TCP port 10003. Discovery mechanism is not implemented.

Each toggle button can be wired to other components such as gain, etc. Audio never passes through this component.

The Layer key has no effect.

When the Ref button is on, the level knob is disabled.

LED intensity can be controlled on the Setup page.

This was tested using Q-Sys 9.12.1 and DadMom firmware 1.0.1.4.

[Plugin is based on the \[https://bitbucket.org/qsc-communities/basicpluginframework/src/main/\]BasicPluginFramework from QSC and includes the VS Code submodule for easy compiling.](https://bitbucket.org/qsc-communities/basicpluginframework/src/main/)
