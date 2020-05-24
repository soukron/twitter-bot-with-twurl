#!/bin/bash
#
# Twitter bot using twurl
#
# by Sergio G. <soukron@gmbros.net>
#
# TODO:
#   - create functions to interact with the API
#   - specifically when getting the tweets: sanitize them properly
#   - read .twurlrc content from env vars
#   - shellcheck

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

# fav ultimo tweet de ciertas cuentas
fav_tweets() {
  for _account in ${BOT_FAVTWEETS:-@twitter}; do
    echo "$(pdate)" - FAV - Getting last tweet from account - account: "${_account}"
    readarray -t _tweet< <( twurl "/1.1/statuses/user_timeline.json?screen_name=${_account}&count=1&tweet_mode=extended&exclude_replies=true&include_rts=false" | jq -r '.[0] | [.id, .full_text, .favorited]' )

    if [[ "${_tweet[3]}" == "   false" ]]; then
      echo "$(pdate)" - FAV - Favoriting last tweet from account - account: "${_account}", id: "${_tweet[1]%?}", text: "${_tweet[2]}"
      twurl -X POST "/1.1/favorites/create.json?id=$( echo "${_tweet[1]%?}" | xargs )" >/dev/null 2>&1
    else
      echo "$(pdate)" - FAV - Skipping favorite \(already favorited\) - account: "${_account}", id: "${_tweet[1]%?}", text: "${_tweet[2]}"
    fi
  done
}

# copiar tweets de ciertas cuentas a las 9:00, 14:00 y 19:00
copy_tweets() {
  _currTime=$( date +"%H%M" )
  _account=$( shuf -e ${BOT_COPYTWEETS:-@twitter} | head -n 1 )

  case "${_currTime}" in
    "0900" | "1200" | "1900")
      echo "$(pdate)" - COPY - Getting last tweet from account - account: "${_account}"
      readarray -t _tweet< <( twurl "/1.1/statuses/user_timeline.json?screen_name=${_account}&count=1&tweet_mode=extended&exclude_replies=true&include_rts=false" | jq -r '.[0] | [.id, .full_text]' )
      _status=$( echo ${_tweet[2]} | tail -c +2 | head -c -2 )

      echo "$(pdate)" - COPY - Publishing new tweet copied from account - account: "${_account}", time: "${_currTime}", status: "${_status}"
      twurl -X POST "/1.1/statuses/update.json?status=${_status}" >/dev/null 2>&1
      ;;
    *)
      echo "$(pdate)" - COPY - Skipping copying tweets \(not the right time\) - account: "${_account}", time: "${_currTime}"
      ;;
  esac
}

# copy .twurlrc to $HOME
prepare_twurl() {
  echo "$(pdate)" - PREPARE - Creating .twurlrc from ENV vars - BOT_USERNAME, BOT_CONSUMER_KEY, BOT_CONSUMER_SECRET, BOT_TOKEN, BOT_SECRET

  cat <<EOF> "${HOME}/.twurlrc"
---
profiles:
  ${BOT_USERNAME}:
    ${BOT_CONSUMER_KEY}:
      username: ${BOT_USERNAME}
      consumer_key: ${BOT_CONSUMER_KEY}
      consumer_secret: ${BOT_CONSUMER_SECRET}
      token: ${BOT_TOKEN}
      secret: ${BOT_SECRET}
configuration:
  default_profile:
  - ${BOT_USERNAME}
  - ${BOT_CONSUMER_KEY}
EOF
}

# acciones
main() {
  start
  prepare_twurl
  followback
  fav_tweets
  copy_tweets
  end
}

main
