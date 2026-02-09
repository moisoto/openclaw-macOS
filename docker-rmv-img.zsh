./docker-stop.zsh

img_list=$(docker images -q openclaw:local)

if [[ ! -z "$img_list" ]]; then
  echo "Removing OpenClaw Images"
  echo $img_list | xargs -r docker rmi
else
  echo "No image detected"
fi
