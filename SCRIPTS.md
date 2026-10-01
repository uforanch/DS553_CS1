I will call the two computers in the exercise the `runner` (remote given to us by Randy to run our projects on) and the `monitor` (remote that checks against red team attacks)

To set up, run `init_all.sh` on the `monitor` after setting variables. 

* `connect_mykey.sh`
  * utility/test script - connect with "mykey"
* `connect_student_admin_key.sh`
  * utility/test scritp - connect with student admin key
* `config.env` 
  * Put in the same folder as `init_all.sh` and set vars before running
* `init_all.sh`
  * Run manually on `monitor`
  * Clones repo, moves to aux scripts folder to run rest of scripts
  * Set up environment variables for `monitor`
  * Install Cron on `monitor`
  * Runs `key_setup`
  * Runs `init_main.sh` on `runner`
  * Runs `set_cronjobs.sh` on `runner` 
* `key_setup.sh`
  * Meant to be run once on `monitor` with an existent authorized keys file
  * Generates a key and puts it in the authorized keys file.
* `init_main.sh`
  * Runs from `monitor` to set up `runner`
  * Runs `lockdown.sh`
  * Runs `deploy.sh`
  * does not run `set_cronjobs.sh`, otherwise every time there's an error we'd get more cron jobs
* `lockdown.sh`
  * Runs from `monitor` to set up `runner`
  * Assumes student-admin key
  * Copies authorized keys file to other computer 
* `deploy.sh`
  * Runs from `monitor` to set up `runner`
  * Kills previous process if there
  * Uses uv to install repo
* `set_cronjobs.sh`
  * Runs from `monitor`
  * Runs a cron job on `monitor` to run `check_secure.sh` every so often
  * Runs a cron job on `runner` to run `check_git_pull.sh`
* `check_secure.sh`
  * Checks if student-admin account key gets in 
  * Checks if app running on port
  * Checks if git commit 
  * If not, run `init_main.sh` to lock down `runner` and deploy the repo again
    * Additionally, kill the cron jobs, wait five minutes for the install, start them again
*  `red_team_attack.sh`
  * Can be run on any device with a VPN to get past WPI firewall.
  * perform the red team attack with random times and ordering


# further ideas
* cron jobs post to webhooks when there is a problem
* arguments and warnings on scripts
* log creation
