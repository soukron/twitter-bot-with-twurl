#!/bin/bash

# set timezone
TZ='Europe/Madrid'; export TZ

# formato de fecha para log
pdate() {
 date +"%Y-%m-%d %H:%M:%S"
}

# inicio
start() {
  echo "$(pdate)" ---------------------------
  echo "$(pdate)" - MAIN - Starting execution
}

# fin
end() {
  echo "$(pdate)" - MAIN - End of execution
}

# follow back a los ultimos 100 nuevos followers
followback() {
  _ngroupies=100

  echo "$(pdate)" - FOLLOWBACK - Getting last followers not being followed - n: "${_ngroupies}"
  _groupies=$( twurl "/1.1/friendships/lookup.json?user_id=$( twurl "/1.1/followers/ids.json?count=${_ngroupies}&stringify_ids=true" | jq -r '.ids[]' | tr -s "\n" "," ) " | jq -r '.[] | select (.connections[0] != "following" and .connections[1] != "following") | [.id] | .[]' )
  echo "$(pdate)" - FOLLOWBACK - Groupies list - ids: "${_groupies}"

  for _groupie in ${_groupies}; do
    echo "$(pdate)" - FOLLOWBACK - Following back - id: "${_groupie}"
    twurl -X POST "/1.1/friendships/create.json?user_id=${_groupie}&follow=true" >/dev/null 2>&1
  done
}

# fav ultimo tweet de @aoc_spain
fav_aoc() {
  _account="@aoc_spain"

  echo "$(pdate)" - FAV - Getting last tweet from account - account: "${_account}"
  readarray -t _tweet< <( twurl "/1.1/statuses/user_timeline.json?screen_name=${_account}&count=1&tweet_mode=extended&exclude_replies=true&include_rts=false" | jq -r '.[0] | [.id, .full_text, .favorited]' )

  if [[ "${_tweet[3]}" == "   false" ]]; then
    echo "$(pdate)" - FAV - Favoriting last tweet from account - account: "${_account}", id: "${_tweet[1]%?}", text: "${_tweet[2]}"
    twurl -X POST "/1.1/favorites/create.json?id=$( echo "${_tweet[1]%?}" | xargs )" >/dev/null 2>&1
  else
    echo "$(pdate)" - FAV - Skipping favorite \(already favorited\) - account: "${_account}", id: "${_tweet[1]%?}", text: "${_tweet[2]}"
  fi

}

# copiar tweets de
#  - @vlcextra
#  - @MeridianoHorta
#  - @levante_emv
#  - @elmundotoday
# a las 9:00, 14:00 y 19:00
copy_tweets() {
  _currTime=$( date +"%H%M" )

  case "${_currTime}" in
    "9000" | "1200" | "1900")
      _account=$( shuf -e vlcextra elmundotoday levante_emv MeridianoHorta | head -1 )

      echo "$(pdate)" - COPY - Getting last tweet from account - account: "${_account}"
      readarray -t _tweet< <( twurl "/1.1/statuses/user_timeline.json?screen_name=${_account}&count=1&tweet_mode=extended&exclude_replies=true&include_rts=false" | jq -r '.[0] | [.id, .full_text]' )
      _status=$( echo "${_tweet[2]}" | tail -c +2 | head -c -2 )

      echo "$(pdate)" - COPY - Publishing new tweet copied from account - account: "${_account}", status: "${_status}"
      twurl -X POST "/1.1/statuses/update.json?status=${_status}" >/dev/null 2>&1
      ;;
    *)
      echo "$(pdate)" - COPY - Skipping copying tweets \(not the right time\) - account: "${_account}", time: "${_currTime}"
      ;;
  esac
}

# copy .twurlrc to $HOME
prepare_twurl() {
  echo "$(pdate)" - PREPARE - Copying .twurlrc - "$( cp -v "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/.twurlrc "${HOME}"/.twurlrc )"
}

# acciones
main() {
  start
  prepare_twurl
  followback
  fav_aoc
  copy_tweets
  end
}

main
