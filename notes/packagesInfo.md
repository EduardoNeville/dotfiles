
## Audio links:

We use Pipewire

Follow this markdown:

[Install Pipewire in Fedore](https://gist.github.com/AlexString/4b352ee28bbf55acb2e8ea7c7a7a6032)

GUI for audio control:

[PWVUCONTROL](https://github.com/saivert/pwvucontrol)

More info on pipewire:

[More Info](https://wiki.archlinux.org/title/PipeWire#WirePlumber)

## DPMS (Display Power Management Signaling)

Useful link:

[Here](https://wiki.archlinux.org/title/Display_Power_Management_Signaling)

| Command | Description |
|----|----|
|xset s off | 	Disable screen saver blanking |
|xset s 3600 3600 	| Change blank time to 1 hour |
|xset -dpms |	Turn off DPMS |
|xset s off -dpms 	| Disable DPMS and prevent screen from blanking |
|xset dpms force off |Turn off screen immediately |
|xset dpms force standby |Standby screen |
|xset dpms force suspend |Suspend screen |

```bash
xset dpms 0 0 0
```
which sets all the DPMS timeouts to zero, could be a better way to "disable" DPMS, since the effect of -dpms would be reverted when, for example, turning off the screen with xset dpms force off.
