#!/bin/zsh

# 1. Prompt for customizable naming & metadata components
echo -n "Name of video series? (Ignore if you dont want to change): "
read -r series_name
echo ""

echo -n "Add dynamic (…) | #Part [Number of video] ?(y/n): "
read -r add_part_flag
echo ""

echo -n "Suffix ? (like an emoji; Ignore if you dont want): "
read -r suffix_input
echo ""

echo -n "Enter Video Description? (e.g. 'Exploring insane AI tools in 2026'; Ignore to skip): "
read -r description_input
echo ""

echo -n "Enter Keywords/Tags? (e.g. 'AI, Artificial Intelligence, Tech Shorts, Automation'; Ignore to skip): "
read -r keywords_input
echo ""

mkdir -p 4K60FPS

files=(*.mp4(N))
total=${#files[@]}

if (( total == 0 )); then
  echo "No MP4 files found."
  exit 1
fi

spin=('|' '/' '-' '\')
current=0

for f in "${files[@]}"; do
  current=$((current + 1))
  percent=$((current * 100 / total))
  
  # Calculate progress bar fill
  bar_size=30
  filled=$((percent * bar_size / 100))
  empty=$((bar_size - filled))
  bar=$(printf "%${filled}s" '' | tr ' ' '#')$(printf "%${empty}s" '' | tr ' ' '-')
  
  # Build the dynamic output filename based on user inputs
  base_title="${series_name:-${f%.*}}"
  part_str=""
  if [[ "$add_part_flag" =~ ^[Yy]$ ]]; then
    part_str="... | #Part ${current}"
  fi
  
  suffix_str=""
  if [[ -n "$suffix_input" ]]; then
    suffix_str=" ${suffix_input}"
  fi
  
  clean_title="${base_title}${part_str}${suffix_str}"
  output_filename="4K60FPS/${clean_title}.mp4"

  # Assemble metadata flags dynamically
  meta_flags=(-metadata "title=${clean_title}" -metadata "creation_time=now")
  if [[ -n "$description_input" ]]; then
    meta_flags+=(-metadata "description=${description_input}")
    meta_flags+=(-metadata "comment=${description_input}")
  fi
  if [[ -n "$keywords_input" ]]; then
    meta_flags+=(-metadata "keywords=${keywords_input}")
  fi

  # Start FFmpeg silently in the background
  ffmpeg -y -i "$f" "${meta_flags[@]}" -bitexact -vf "scale='if(gt(iw,ih),3840,-2)':'if(gt(iw,ih),-2,3840)':flags=lanczos" -r 60 -c:v libx264 -preset slow -crf 17 -c:a copy "$output_filename" >/dev/null 2>&1 &
  pid=$!

  # Animate spinner while FFmpeg process runs
  spin_idx=1
  while kill -0 $pid 2>/dev/null; do
    printf "\r[%s] %s %3d%% (%d/%d) Processing: %s" "$bar" "${spin[$spin_idx]}" "$percent" "$current" "$total" "$f"
    spin_idx=$(( (spin_idx % 4) + 1 ))
    sleep 0.15
  done
done

printf "\r[%s] 100%% (%d/%d) Done!                                        \n" "$bar" "$total" "$total"
printf "\033[32mVIDEOS CONVERTED SUCCESSFULLY\033[0m\n"
