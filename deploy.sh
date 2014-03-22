#!/bin/sh
ssh deployer@harryrickards.com "cd apps/social_impact;git pull;./kill.sh;bundle exec unicorn -c config/unicorn.rb -D"
