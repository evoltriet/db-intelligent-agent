local ftcsv = require('ftcsv')
local utils = require('utils')
local alert_smtp = require('alert_smtp')
local socket = require 'socket'

--mappings where key is blocker
blockers = {}
time_blocked_mappings = {}
users_blocked_mappings = {}
need_alerts = {}
alerted = {}

while(true)
do
   local blockings, headers = ftcsv.parse("testblockingsessions.csv", ",")
   clean_beliefs()
   --(need this here for some reason to ensure asyncrhonous execution between clean_bliefs and perceive_blockings)
    for k,v in pairs(blockers) do
        need_alert_bool = check_need_alert(k)
    end

   --perceive information from environment
   numrows = 0
   for k, v in pairs(blockings) do
        numrows = numrows + 1
        blocking_sid = v["BLOCKING_SID"]
        sql_id = v["SQL_ID"]
        blocked_sid = v["BLOCKED_SID"]
        blocked_username = remove_special_chars(v["BLOCKED_USERNAME"])
        blocked_machine = remove_special_chars(v["BLOCKED_MACHINE"])
        blocker = blocking_sid.."-"..sql_id

        if not setContains(blockers, blocker) then
            addToSet(blockers, blocker)
            set_start_time(blocker)
        end

        perceive_blockings(blocker, blocked_sid, blocked_username, blocked_machine)  
    end
    print(string.format("Current blockings: %s", numrows))

    --check if alerts needed
    totalblockers = 0
    for k,v in pairs(blockers) do
        totalblockers = totalblockers + 1
        need_alert_bool = check_need_alert(k)
        time_blocked = check_time_blocked(k)
        users_blocked = check_users_blocked(k)
        print(k)
        print(need_alert_bool)
        print(time_blocked)
        print(users_blocked)
        if (need_alert_bool) then
            addToSet(need_alerts, k)
            time_blocked_mappings[k] = time_blocked
            users_blocked_mappings[k] = users_blocked
        end
    end
    print(string.format("Total blockers found: %s", totalblockers))
    --print(dump(blockers))
    --print(dump(time_blocked_mappings))
    --print(dump(users_blocked_mappings))
    --print(dump(need_alerts))
    --print(dump(alerted))

    --handle alerts
    for k,v in pairs(need_alerts) do
        if not setContains(alerted, k) then
            t = split(k, "-")
            session_id = t[1]
            time_blocked = secondsToClock(time_blocked_mappings[k])
            users_blocked = users_blocked_mappings[k]

            msg_body = "Notification: A session has been found to cause harmful blockings.\n"..
            "Session id: "..session_id.."\n"..
            "Has been blocking for: "..time_blocked.." (hh:mm:ss)\n"..
            "Number of users/machine affected: "..users_blocked.."\n\n"

            print(msg_body)
            send_email(msg_body)
            addToSet(alerted, k)
            --for logging purposes
            logfile = io.open("testlogs.txt", "a")
            io.output(logfile)
            io.write(msg_body)
            io.close(logfile)
        end
    end

    print("end of reasoning cycle\n")
    socket.sleep(7)
end

