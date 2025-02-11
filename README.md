# DadMom Controller

This is a Q-Sys plugin for the Monitor Operating Module. Unaffiliated with Digital Audio Denmark.

Communicates with the DadMom controller via unicast TCP port 10003. Discovery mechanism is not implemented.

Each toggle button can be wired to other components such as gain, etc. Audio never passes through this component.

The plugin provides 12 Spkr and Src toggle buttons which can be wired to other components. These are divided into 4 layers on the hardware device.

When the Ref button is on, level is locked to 0dB.

LED intensity can be controlled on the Setup page.

The Identify button on the Setup page will light up all LEDs green for 10 seconds.

This was tested using Q-Sys 9.12.1 and DadMom firmware 1.0.1.4.

### Example design wiring
![QDS example](https://github.com/user-attachments/assets/050656a1-e55f-427c-ab76-9e28a4e963f7)


Plugin is based on the [BasicPluginFramework](https://bitbucket.org/qsc-communities/basicpluginframework/src/main/) from QSC and includes the VS Code submodule for easy compiling.
