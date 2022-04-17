#!/bin/bash

video=false
audio=false

help (){
  echo "syntax : redviddown [args] URL"
  echo "args :  --audio for audio only"
  echo "        --video for video only"
  echo "        without args, download a video with the sound"
  exit 1
}

if ! [ -x "$(command -v wget)" ]; then
  echo "wget command missing"
  exit 1
fi

if ! [ -x "$(command -v ffmpeg)" ]; then
  echo "ffmpeg command missing"
  exit 1
fi

if [ "$#" == "0" ]; then
  help

else
  for i in "$@"; do
    if [ "$i" == "--audio" ]; then
      audio=true
    elif [ "$i" == "--video" ]; then
      video=true
    fi
  done

  URL=${!#}
  if [[ "$URL" != "https://"* ]]; then 
    echo "No valid URL detected" 
    help
  fi
fi

IFS=/ read -ra string <<< "$URL"
l=${#string[@]}
name=${string[$((l-1))]}

wget -O reddit.json "$URL.json"  > /dev/null 2>&1
file=$(cat reddit.json)
for i in $file
do
  if [[ "$i" == *"?source=fallback"* ]];then
    substr="?source=fallback\","
    media_url=$(echo $i | sed "s@$substr@@" | sed "s/^.//g")
  fi
done

output="$name.mp4"
audio_url=${media_url/"DASH_"*/"DASH_audio.mp4"}

get_video (){
  echo "downloading video for $name"
  wget -O "video_$name.mp4" $media_url  > /dev/null 2>&1
}

get_audio (){
  echo "downloading audio for $name"
  wget -O "audio_$name.mp4" $audio_url  > /dev/null 2>&1
  echo "converting mp4 to mp3. This can take some time"
  ffmpeg -i "audio_$name.mp4" "audio_$name.mp3"  > /dev/null 2>&1
  rm "audio_$output"
}

if [ "$video" = true ]; then
  get_video 
fi

if [ "$audio" = true ]; then
  get_audio 
fi

if [ "$video" = false ] && [ "$audio" = false ]; then
  get_video 
  get_audio
  echo "merging audio and video. This can take some time"
  ffmpeg -i "video_$name.mp4" -i "audio_$name.mp3" -c copy -map 0:v:0 -map 1:a:0 $output > /dev/null 2>&1
  rm "video_$name.mp4" "audio_$name.mp3"
fi

echo "done, cleaning trash"
rm reddit.json
