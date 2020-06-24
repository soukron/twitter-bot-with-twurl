FROM docker.io/ruby:2.4

RUN apt-get update && apt-get install -y jq && gem install twurl && apt-get clean all

RUN mkdir -p /opt/bot/src

COPY bot.sh /opt/bot/src
