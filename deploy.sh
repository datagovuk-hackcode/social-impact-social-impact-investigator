#!/bin/sh
ssh deployer@vps "cd apps/social_impact;git pull;./kill.sh;bundle exec unicorn -c config/unicorn.rb -D"
