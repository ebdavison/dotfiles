#!/usr/bin/env bash

lighticon="$HOME/Pictures/padlock-light.png"
darkicon="$HOME/Pictures/padlock-dark.png"
tmpbg='/tmp/screen.png'
image="$HOME/Pictures/screen.png"

# copy lock image to tmpbg
cp $image $tmpbg

# take a screenshot
#scrot -o "$tmpbg"

# set a threshold value to determine if we should use the light icon or dark
# icon
VALUE="60" #brightness value to compare to

# determine the color of the screenshot
# thanks to [i3lock-fancy](https://github.com/meskarune/i3lock-fancy) for the
# idea of getting the background color to change the icons
COLOR=$(convert "$tmpbg" -gravity center -crop 100x100+0+0 +repage -colorspace hsb \
    -resize 1x1 txt:- | awk -F '[%$]' 'NR==2{gsub(",",""); printf "%.0f\n", $(NF-1)}');

# change the color ring colors to leave the middle of the feedback ring
# transparent and the outside to use either dark or light colors based on the 
# screenshot
if [ "$COLOR" -gt "$VALUE" ]; then #light background, use dark icon
    icon="$darkicon"
    PARAM=()
    # PARAM=(--textcolor=00000000 --insidecolor=00000000 --ringcolor=0000003e \
    #     --linecolor=00000000 --keyhlcolor=ffffff80 --ringvercolor=ffffff00 \
    #     --separatorcolor=22222260 --insidevercolor=ffffff1c \
    #     --ringwrongcolor=ffffff55 --insidewrongcolor=ffffff1c)
else # dark background so use the light icon
    icon="$lighticon"
    PARAM=()
    # PARAM=(--textcolor=ffffff00 --insidecolor=ffffff00 --ringcolor=ffffff3e \
    #     --linecolor=ffffff00 --keyhlcolor=00000080 --ringvercolor=00000000 \
    #     --separatorcolor=22222260 --insidevercolor=0000001c \
    #     --ringwrongcolor=00000055 --insidewrongcolor=0000001c)
fi

# blur the screenshot by resizing and scaling back up
convert "$tmpbg" -filter Gaussian -thumbnail 20% -sample 500% "$tmpbg"

# overlay the icon onto the screenshot
convert "$tmpbg" "$icon" -gravity center -composite "$tmpbg"

# lock the screen with the color parameters
/usr/bin/env i3lock "${PARAM[@]}" -i "$tmpbg"

