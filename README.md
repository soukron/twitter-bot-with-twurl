# Twitter Bot (using twurl)
## Description
This is the code of a bot written in bash and leveragin in [twurl](https://github.com/twitter/twurl) the interaction with Twitter API.

The code is in `src/bot.sh` and there's a `Makefile` with some helper commands to run it in a container image which Ruby 2.4 and the twurl gem file.

## Configuration
The bot uses environment variables to change some settings. 

All the configuration is done in the `config/default.env`. Contains the configuration variables to:
  - build and publish the image to a remote registry:
    - *NAME*. Name of the bot. Used in Makefile for help.
    - *IMAGE_NAME*. Name of the image to be built.
    - *IMAGE_VERSION*. Version of the bot to tag the image.
    - *REGISTRY_HOSTNAME*. Name of the registry where the image must be published.
    - *REGISTRY_NAMESPACE*. Namespace in the registry where to push the image.
  - connect to Twitter's API
    - *BOT_USERNAME*. Name of the Twitter acount for the bot.
    - *BOT_CONSUMER_KEY*. Consumer key of the bot application.
    - *BOT_CONSUMER_SECRET*. Consumer secret of the bot application.
    - *BOT_TOKEN*. OAuth token to authenticate in the API.
    - *BOT_SECRET*. OAuth secret to authenticat in the API.
  - control the bot behavior
    - *BOT_FAVTWEETS*. List of accounts to like each of their tweets.
    - *BOT_COPYTWEETS*. List of accounts to copy their tweets a few times per day.

The `Makefile` has a variable to store multiple configuration files so you can run multiple instances of 
the bot with different configurations:
```
$ make CONFIG=myotherbot.env run
```

## Bot actions
The bot has three main behaviors:
 - Follow back.
 - Likes the last tweet of the accounts listed in `BOT_FAVTWEETS` variable.
 - Publishes three times per day (not yet configurable) a tweet copied from a random account choosen from the ones listed in `BOT_COPYTWEETS` variable.

## Basic Usage
### No containers at all
A valid Ruby 2.4 installation with twurl gem must be installed prior to run the command:
```
$ make run-bot
```

### Using container images
A valid docker runtime must be installed prior to run the commands:
```
$ make run       # in order to use quay.io/soukron/twurl:latest image
$ make run-local # in order to use any locally built image
```

## Scheduled execution
The most simple approach is to have a crontab entry for each execution:
```
$ crontab -l
*/10 * * * * cd /home/soukron/.local/gmbros.net/mycustombot/ && make CONFIG=mycustombot.env run
```

## Building the image
Build the image for local testing (using `dockerfiles/twurl/Dockerfile`):
```
$ make build
```

Publishing the image to a remote registry with the VERSION tag (configured in the `VERSION` file):
```
$ make tag
$ make publish
```

## Contact
Reach me in [Twitter](http://twitter.com/soukron) or email in soukron _at_ gmbros.net

## License
Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the 
License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
CONDITIONS OF ANY KIND, either express or implied. See the License for the 
specific language governing permissions and limitations under the License.

[here]:http://gnu.org/licenses/gpl.html



