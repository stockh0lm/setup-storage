# load kernel modules for usb keyboard support

kernelmodules="rtc floppy parport_pc usbkbd usb-uhci keybdev"

for mod in $kernelmodules; do
    [ "$verbose" ] && echo loading kernel module $mod
    modprobe -a $mod
done
