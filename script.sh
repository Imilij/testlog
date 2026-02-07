#!/usr/bin/env bash

LOG_FILE="$1"
MODE="$2"
SEARCH_TERM="$3"

[ -z "$LOG_FILE" ] || [ -z "$MODE" ] && { echo "Usage: $0 <log> <mode>"; exit 1; }
[ ! -f "$LOG_FILE" ] && { echo "Error: $LOG_FILE not found"; exit 1; }

if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
    cd "$OUTPUT_DIR" || exit 1
fi

TOTAL_REQ=$(wc -l < "$LOG_FILE")

run_analysis() {
    local mode=$1
    local f
    
    case "$mode" in
        ip) f=analysis_ip.csv; awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v h="ip:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        uagent) f=analysis_uagent.csv; awk -F'"' '{if($6 != "") print $6}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v t="$TOTAL_REQ" 'BEGIN{print "user_agent:"} {count=$1; $1=""; sub(/^[[:space:]]+/, ""); printf " %s: %d\n", $0, count} END{print "Total_requests: "t}' > "$f";;
        date) f=analysis_date.csv; awk '{gsub(/^\[|\].*$/,"",$4); print $4}' "$LOG_FILE" | cut -d: -f1 | sort | uniq -c | sort -nr | awk -v h="date:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        date+h) f=analysis_date_h.csv; awk '{gsub(/^\[|\]/,"",$4); split($4,d,":"); printf "%s:%s\n",d[1],d[2]}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v h="date+hour:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        date+m) f=analysis_date_m.csv; awk '{gsub(/^\[|\]/,"",$4); split($4,d,":"); printf "%s:%s:%s\n",d[1],d[2],d[3]}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v h="date+hour+minute:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        date+s) f=analysis_date_s.csv; awk '{gsub(/^\[|\]/,"",$4); print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v h="date+hour+minute+second:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        type) f=analysis_type.csv; awk -F'"' '{split($2,m," "); print m[1]}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v h="request_type:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s_request: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        reply) f=analysis_reply.csv; awk '{code=$9; if(code ~ /^5/) code="5**"; else if(code !~ /^[234]/) code="Another"; print code}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk -v h="reply_code:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s_request: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
        request) f=analysis_request.csv; awk -F'"' '{print $2}' "$LOG_FILE" | sed 's/ HTTP.*$//' | cut -d' ' -f2 | sort | uniq -c | sort -nr | awk -v h="request_path:" -v t="$TOTAL_REQ" 'BEGIN{print h} {printf " %s: %d\n",$2,$1} END{print "Total_requests: "t}' > "$f";;
    esac
    
    echo "Created: $f"
}

git_push() {
    if [ -n "$GIT_TOKEN" ]; then
        git remote set-url origin https://${GIT_TOKEN}@github.com/Imilij/testlog.git 2>/dev/null
        git add analysis_*.csv script.sh 2>/dev/null
        git commit -m "$1" 2>/dev/null
        git push origin main 2>/dev/null
    fi
}

case "$MODE" in
    search)
        [ -z "$SEARCH_TERM" ] && { echo "Error: search requires term"; exit 1; }
        f=analysis_search.csv
        COUNT=$(grep -F "$SEARCH_TERM" "$LOG_FILE" | wc -l)
        echo "search result \"$SEARCH_TERM\": $COUNT" > "$f"
        echo "Created: $f (found: $COUNT)"
        ;;
    all)
        echo "Running analysis for all modes..."
        for mode in ip uagent date date+h date+m date+s type reply request; do
            echo "Processing: $mode"
            run_analysis "$mode"
        done
        echo "All analyses completed!"
        git add analysis_*.csv script.sh 2>/dev/null && git commit -m "Analysis: all modes ($TOTAL_REQ)" 2>/dev/null && git push origin main -f 2>/dev/null
        exit 0
        ;;
    ip|uagent|date|date+h|date+m|date+s|type|reply|request)
        run_analysis "$MODE"
        git add "$(ls -t analysis_*.csv | head -1)" script.sh 2>/dev/null && git commit -m "Analysis: $MODE ($TOTAL_REQ)" 2>/dev/null && git push origin main -f 2>/dev/null
        ;;
    *)
        echo "Modes: ip|uagent|date|date+h|date+m|date+s|type|reply|request|search|all"
        exit 1
        ;;
esac

