Show in doc:
* Docker machines that I used for tests
  * Make a repo just for that
* Mention failed scripts
* Show the redeploy message

SCRIPT CHANGES:
Add in something to check 
move git pull to the linux thing, remove the other cron job


AAAAA if the thing is redeployed... it'll take several minutes to set it up 

# IDEA:
Have two seperate cron jobs for site running or site going OR just combine all including github update, probably best idea (edit set cronjobs accordingly)

Kill the cron jobs if there's a problem (maybe make a kill cron jobs script?)

sleep for like five mintues 

redeplot cron jobs

removing the github one or moving it to monitor is essential

ADD: pskill remote on redeploy (Just in deploy.sh) 



# ALT IDEA
just run things evety 6 minutes
