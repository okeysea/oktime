#!/usr/bin/env bash

sig=0
sigExit=30
sigQuit=29
sigWinCh=28

sigh=35
sigj=36
sigk=37
sigl=38
sigH=39
sigJ=40
sigK=41
sigL=42
sigs=43
sigp=44

gStartTime=`date +"%s"`

gState="menu"

gPrevM2=-1
gPrevM1=-1
gPrevS2=-1
gPrevS1=-1

gTimeColStep=7
gTimeSeparatorStep=3

gWatchSizeX=$(( gTimeColStep * 4 + gTimeSeparatorStep ))
gWatchSizeY=7

gWinWidth=`tput cols`
gWinHeight=`tput lines`

gWaitTime=0.2
gTimeDisplayMode=1

gMenuMax=1
gMenus=("[s]topwatch" "[p]omodoro")
gMenusLength=22
gMenuCursor=0
gMenuPrevious=-1

function Time()
{
  while :; do
    tput setaf 1 && printf -v start_day '%(%a %b %e %Y)T'
    day=$start_day

    clear
    echo "$day"
    while sleep 1 && [[ $start_day = $day ]]; do
      printf -v day '%(%a %b %e %Y)T'
      printf '\r%(%I:%M %p)T'
    done
  done
}

function Usage
{
  cat << EOF
USAGE: HOGEHOGE
EOF
}

function KeyReceive()
{
  local pidDisplay key cESC akey
  pidDisplay=$1

  akey=(0 0 0)

  cESC=`echo -ne "\033"`

  trap "Exit;" INT TERM
  trap "ExitSub;" $sigExit

  while :; do
    read -s -n 1 key

    akey[0]=${akey[1]}
    akey[1]=${akey[2]}
    akey[2]=$key

    sig=0

    if [[ $key == $cESC && ${akey[1]} == $cESC ]]; then
      Exit
    elif [[ $key == "h" ]]; then sig=$sigh
    elif [[ $key == "j" ]]; then sig=$sigj
    elif [[ $key == "k" ]]; then sig=$sigk
    elif [[ $key == "l" ]]; then sig=$sigl
    elif [[ $key == "s" ]]; then sig=$sigs
    elif [[ $key == "p" ]]; then sig=$sigp
    else sig=0
    fi

    if [[ $sig != 0 ]]; then
      kill -$sig $pidDisplay
    fi
  done
}

function Display()
{
  local sigThis
  trap "sig=$sigQuit;" $sigQuit
  trap "exit;" $sigExit

  # ウインドウサイズ変更
  trap "DisplayRefresh" $sigWinCh

  trap "sig=$sigh;" $sigh
  trap "sig=$sigj;" $sigj
  trap "sig=$sigk;" $sigk
  trap "sig=$sigl;" $sigl
  trap "sig=$sigs;" $sigs
  trap "sig=$sigp;" $sigp

  tput clear

  while :; do
    sleep 0.2
    sigThis=$sig
    sig=0

    UpdateState $sigThis
    DrawScreen
  done
}

function UpdateState()
{
  local local_sig
  local_sig=$1

  if ((gState == "menu")); then
    if (( "$local_sig" == "$sigh" )); then
      gMenuCursor=$((gMenuCursor - 1))
    elif (( "$local_sig" == "$sigl" )); then
      gMenuCursor=$((gMenuCursor + 1))
    fi
    
    if [ $gMenuCursor -lt 0 ]; then
      gMenuCursor=0
    fi

    if [ $gMenuCursor -gt $gMenuMax ]; then
      gMenuCursor=$gMenuMax
    fi
  fi
}

function DrawScreen()
{
  local ypos

  if [[ "$gState" == "menu" ]]; then
    if [[ "$gMenuPrevious" != "$gMenuCursor" ]]; then
      ypos=$(CalcHalfPos $gWinHeight $gWatchSizeY)
      ((ypos = ypos + gWatchSizeY + 1))

      tput cup $ypos $(CalcHalfPos $gWinWidth  $gMenusLength)

      for i in "${!gMenus[@]}"; do
        if [[ "$i" == "$gMenuCursor" ]]; then
          NumChar "${gMenus[$i]}"
          echo -ne " "
        else
          echo -ne "${gMenus[$i]}"
          echo -ne " "
        fi
      done
      gMenuPrevious=$gMenuCursor

      # にぎやかし
      DisplayTime 0 \
        $(CalcHalfPos $gWinWidth  $gWatchSizeX) \
        $(CalcHalfPos $gWinHeight $gWatchSizeY)
    fi
  elif [[ "$gState" == "stopwatch" ]]; then
    DisplayTime $(( $(date +"%s") - gStartTime )) \
      $(CalcHalfPos $gWinWidth  $gWatchSizeX) \
      $(CalcHalfPos $gWinHeight $gWatchSizeY)
  fi
}

function Exit()
{
  kill -$sigExit $pidDisplay
  tput clear
  ExitSub
}

function ExitSub()
{
  exit
}

function UpdateScreenInfo()
{
  local width height
  width=`tput cols`
  height=`tput lines`

  gWinWidth=$width
  gWinHeight=$height
}

function DisplayRefresh()
{
  UpdateScreenInfo
  tput clear
  gPrevM2=-1
  gPrevM1=-1
  gPrevS2=-1
  gPrevS1=-1
  gMenuPrevious=-1
}

function CalcHalfPos()
{
  n1=$1
  n2=$2

  echo -n $(( (n1 / 2) - (n2 / 2) ))
}

function DefNums()
{
  cat << EOF
######
#....#
#....#
#....#
#....#
#....#
######

.....#
.....#
.....#
.....#
.....#
.....#
.....#

######
.....#
.....#
######
#.....
#.....
######

######
.....#
.....#
######
.....#
.....#
######

#....#
#....#
#....#
######
.....#
.....#
.....#

######
#.....
#.....
######
.....#
.....#
######

######
#.....
#.....
######
#....#
#....#
######

######
.....#
.....#
.....#
.....#
.....#
.....#

######
#....#
#....#
######
#....#
#....#
######

######
#....#
#....#
######
.....#
.....#
######

..
##
##
..
##
##
..

......
......
......
......
......
......
......
EOF
}

function SandwichStr()
{
  echo -ne "$1" && echo -ne "$2" && echo -ne "$3"
}

function NumChar()
{
  local str
  str=${1:-" "}
  SandwichStr "$(tput setab 4)" "$str" "$(tput sgr0)"
}

function EmptyChar()
{
  local str
  str=${1:-" "}
  SandwichStr "$(tput setab 0)" "$str" "$(tput sgr0)"
}

function NumStr()
{
  local input step stl edl charp

  step=8
  input=$1
  charp=`NumChar`
  emptp=`EmptyChar`

  ((stl = input * step + 1 ))
  ((edl = stl + step - 2 ))

  DefNums | sed -n -e "${stl},${edl}s/#/${charp}/g" \
    -e "${stl},${edl}s/\\./${emptp}/g" \
    -e "${stl},${edl}p"
}

function PutNumToDisplay()
{
  local baseX baseY awksc
  baseX=$2
  baseY=$3

  awksc="{\"tput cup \"$baseY+(NR-1)\" $baseX\" | getline t; printf t\$0}"

  NumStr $1 | awk "$awksc"
}

function DisplayMMSS()
{
  local str
  local m2 m1 s2 s1 baseX baseY
  local m2x m1x sepx s2x s1x

  str=$1
  baseX=$2
  baseY=$3

  m2=${str:2:1}
  m1=${str:3:1}
  s2=${str:4:1}
  s1=${str:5:1}

  ((m2x= gTimeColStep * 0 + baseX))
  ((m1x= gTimeColStep * 1 + baseX))

  ((sepx = gTimeColStep * 2 + baseX))

  ((s2x= gTimeColStep * 2 + gTimeSeparatorStep + baseX ))
  ((s1x= gTimeColStep * 3 + gTimeSeparatorStep + baseX ))

  # echo "${m2}${m1}:${s2}${s1}"
  if [[ $gPrevM2 -ne $m2 ]]; then
    #PutNumToDisplay 11 0 0
    PutNumToDisplay m2 $m2x $baseY
    gPrevM2=$m2
  fi

  if [[ $gPrevM1 -ne $m1 ]]; then
    #PutNumToDisplay 11 7 0
    PutNumToDisplay m1 $m1x $baseY
    gPrevM1=$m1
  fi

  PutNumToDisplay 10 $sepx $baseY

  if [[ $gPrevS2 -ne $s2 ]]; then
    #PutNumToDisplay 11 21 0
    PutNumToDisplay s2 $s2x $baseY
    gPrevS2=$s2
  fi

  if [[ $gPrevS1 -ne $s1 ]]; then
    #PutNumToDisplay 11 28 0
    PutNumToDisplay s1 $s1x $baseY
    gPrevS1=$s1
  fi
}

function GetSecondToTime()
{
  local h2 h1 m2 m1 s2 s1 
  local second minute hour
  local seconds minutes hours

  second=$1
  minute=$(((second - second % 60) / 60))
  hour=$(((minute - minute % 60) / 60))

  seconds=$((second % 60))
  minutes=$((minute % 60))
  hours=$((hour))

  ((s1 = seconds % 10 ))
  ((s2 = (seconds - s1) / 10 ))

  ((m1 = minutes % 10))
  ((m2 = (minutes - m1) / 10 ))

  ((h1 = hours % 10))
  ((h2 = (hours - h1) / 10))

  # echo "${hour}:${minute}:${second}"
  # echo "${h1}:${m2}${m1}:${s2}${s1}"
  # echo "${hours}:${minutes}:${seconds}"
  echo -en "${h2}${h1}${m2}${m1}${s2}${s1}"
}

function DisplayTime()
{
  local second str baseX baseY

  second=$1
  baseX=$2
  baseY=$3
  str=$(GetSecondToTime $second)

  if [[ $gTimeDisplayMode -eq 1 ]]; then
    DisplayMMSS $str $baseX $baseY
  else
    echo $str
  fi

}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  Usage
elif [[ "$1" == "--number" ]]; then
  NumStr $2
elif [[ "$1" == "--dispn" ]]; then
  clear
  PutNumToDisplay $2 $3 $4
elif [[ "$1" == "--timed" ]]; then
  DisplayMMSS $2 $3 $4
elif [[ "$1" == "--secondtime" ]]; then
  GetSecondToTime $2
elif [[ "$1" == "--time" ]]; then
  Time
elif [[ "$1" == "--show" ]]; then
  Display
else
  bash $0 --show&
  KeyReceive $!
fi
