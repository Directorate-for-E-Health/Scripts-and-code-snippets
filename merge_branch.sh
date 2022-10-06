#!/bin/bash
#log="/home/azureuser/bin/logs/merge.log"
# Script attempts to merge the configured $BRANCH and any children. Be warned of the potential consequences of a merge and monitor the logs. 

BASE_URL="http://localhost:8080" # no trailing slash
BRANCH="$1"
WORK_FOLDER="/home/azureuser/bin"
FILE="$WORK_FOLDER"/"branch_list.txt"
cd "$WORK_FOLDER"

#Save each child branch and loop them
#echo "$BRANCH" > "$FILE"
curl -sX GET --header 'Accept: application/json' "$BASE_URL"'/branches/'"$BRANCH"'/children?immediateChildren=false&page=0&size=10000'|jq -r '.[].path' > "$FILE"

while read line; do
[[ $line =~ [0-9]{4}-[0-9]{2}-[0-9]{2}$  ]] && continue # Skip loop if the branch ends with YYYY-MM-DD
source=$(dirname "$line")
id=$(curl -si --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "source": "'$source'",
  "target": "'$line'"
}' "$BASE_URL"'/merge-reviews'| grep -Eo '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' )

# Check status and loop while status is pending, the while loop runs for 10 mins then logs and aborts
status="PENDING"
i=0
while [ "$status" == "PENDING" ]; do
    status=$(curl -sX GET --header 'Accept: application/json' "$BASE_URL"'/merge-reviews/'"$id"|jq -r '.status' )
    sleep 5 ## So we don't send too many requests
    let "i++"
if [ "$i" -gt 120 ]; then
    echo $(date +"%d-%m-%Y"): "Script stuck in "$status" for over time out limit."
    break
fi
done < "$FILE"

output=$(curl -sX POST --header 'Content-Type: application/json' --header 'Accept: application/json' "$BASE_URL"'/merge-reviews/'"$id"'/apply')
if echo $output | grep -iqF error; then # Log any response with error in it
echo "$(date +"%d-%m-%Y") "$line" with status "$status" gave result: "$output""
fi

done < "$FILE"
rm "$FILE"
