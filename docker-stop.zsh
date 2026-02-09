act_perf="NO"

running_containers=$(docker ps -q --filter ancestor=openclaw:local)
if [[ ! -z "$running_containers" ]]; then
  echo "Stopping Running OpenClaw Containers..."
  echo $running_containers | xargs -r docker stop
  act_perf="YES"
fi

existing_containers=$(docker ps -q -a --filter ancestor=openclaw:local)
if [[ ! -z "$existing_containers" ]]; then
  echo "Removing OpenClaw Containers"
  echo $existing_containers | xargs -r docker rm
  act_perf="YES"
fi

if [[ "$act_perf" != "YES" ]]; then
  echo "Nothing to stop"
fi
