# Script for Analyzing Nginx Ingress Log Files and Converting Them to CSV Format
## How to Run the Script:
General command to execute the script:
```
/bin/bash /analysis_script/script.sh /path/to/nginx.log parameter
```
After the script runs, its results will be stored in a .csv file generated in the script’s directory and automatically pushed to Git.
Each parameter execution creates a separate output file that includes the parameter name in its filename.

Example output file:
```
analysis_ip.csv
```

### Available Run Parameters:

ip – Sorts requests by user IP addresses.

uagent – Sorts requests by user agents.

date – Sorts requests by date.

date+h – Sorts requests by date including hours.

date+m – Sorts requests by date including hours and minutes.

date+s – Sorts requests by date including hours, minutes, and seconds.

type – Sorts requests by request type.

reply – Sorts requests by HTTP response status code.

request – Sorts requests by request path (URL).

search – Counts occurrences of a specific value.

Example of running the script with the search parameter:
```
/bin/bash /analysis_script/script.sh /path/to/nginx.log search "ip-address"
```
all – Sequentially runs all parameters except search.

# Script Description
The script is implemented in Bash, using utilities such as awk, sed, sort, uniq, and grep for text processing.

## Implementation Details
The following component validates the input command:
```
[ -z "$LOG_FILE" ] || [ -z "$MODE" ] && { echo "Usage: $0 <log> <mode>"; exit 1; }
[ ! -f "$LOG_FILE" ] && { echo "Error: $LOG_FILE not found"; exit 1; }
```
Counting the total number of requests:
```
TOTAL_REQ=$(wc -l < "$LOG_FILE")
```
The main logic is encapsulated in the central function:
```
run_analysis()
```
Inside this function, data is filtered based on the selected parameter, unique values are counted, sorted by frequency, and formatted into a .csv file.

Parameters search and all are handled separately due to their distinct logic.

search uses grep -F for exact value matching and counts results with wc -l.

The all parameter is implemented by running the central function run_analysis() with each parameter substituted, for step-by-step execution of each of them.
This parameter has been added to enable script automation using cron jobs.

Full script details can be found in script.sh, and parameter-specific outputs are stored in files named analysis_<parameter>.csv.

## Automation with Cron
Example of adding to crontab for daily analysis:
```
0 0 * * * /bin/bash /analysis_script/script.sh /analysis_script/nginx.log all
```

# Docker Deployment
To simplify deployment, the project includes Dockerfile, docker-compose.yml, and .env configuration files.

The variables git-token, git-user-name, git-user-email, and git-repo were added to the .env file to enable automatic pushing of the output file to Git.
An example of the .env file is provided in the .env.local file.

To run the project in a Docker container, we need to download the Dockerfile and docker-compose.yml files and create an .env file where we can add the generated git-token with the ability to push changes to repositories.

After that, you can deploy the container using the following commands:
```
docker compose build
docker compose up -d
```

## Automation via Cron when using a Docker container
Example of adding to crontab for daily analysis:
```
0 0 * * * docker exec nginx-log-analyzer /app/script.sh /analysis_script/nginx.log all
``` 
