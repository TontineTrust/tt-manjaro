# Manjaro TontineTrust Flavour

Installation consists of:
1. Installing Manjaro Sway
2. Installing `tt`
3. Running `tt install`

## Installing Manjaro Sway

Download a Manjaro Sway ISO. The minimal edition is recommended:
 [https://manjaro-sway.download/]()

Burn the ISO to a USB:
```sh
sudo dd bs=4M if=/path/to/manjaro.iso of=/dev/sd<installer drive letter> status=progress oflag=sync
```

Format your target drive:
```sh
sudo mkfs.etx4 /dev/sd<target drive letter>
```

Boot into the installer USB.

Follow the installer instructions. Make sure to select disk encryption.

Poweroff. Remove the installer USB. Boot into your new Manjaro OS.

Run Manjaro hardware detection:
```sh
mhwd
```

Get internet access. USB tether from your phone if you're in a pinch.

## Installing tt

Run the following to download the `tt` tool and make it executable:

```sh
curl -o https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main/tt.sh --create-dirs ~/.local/bin && chmod u+x ~/.local/bin/tt.sh
```

## Running tt install

Simply run `tt install`.
