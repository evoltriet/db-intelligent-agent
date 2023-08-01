local odbc_driver = require "luasql.odbc"
local utils = require('utils')
local alert_smtp = require('alert_smtp')
local socket = require 'socket'
local config = require "config"

--mappings where key is blocker
blockers = {}
time_blocked_mappings = {}
users_blocked_mappings = {}
need_alerts = {}
alerted = {}

--load config
DB_DNS = config.database.DNS
DB_user = config.database.username
DB_pass = config.database.password

env = assert (odbc_driver.odbc())
con = assert (env:connect(DB_DNS, DB_user, DB_pass))

while(true)
do
   clean_beliefs()
   --(need this here for some reason to ensure asyncrhonous execution between clean_bliefs and perceive_blockings)
    for k,v in pairs(blockers) do
        need_alert_bool = check_need_alert(k)
    end
    --perceive information from environment
    cur = assert (con:execute([[SELECT 
                               l1.sid blocking_sid, l2.sid blocked_sid, s2.username blocked_username, s2.machine blocked_machine, s1.sql_id, s1.username
                            FROM 
                               gv$lock l1, gv$lock l2, gv$session s1, gv$session s2, gv$sqlarea a 
                            WHERE 
                               l1.block = 1 AND 
                               l2.request > 0 AND 
                               l1.id1 = l2.id1 AND 
                               l1.id2 = l2.id2 AND 
                               l1.sid = s1.sid AND 
                               l2.sid = s2.sid AND 
                               a.sql_id = s1.sql_id;]]))
    row = cur:fetch ({}, "a")
    numrows = 0
    while row do
        numrows = numrows + 1
        blocking_sid = ""
        sql_id = ""
        blocked_sid = ""
        blocked_username = ""
        blocked_machine = ""
        if row.BLOCKING_SID then
            blocking_sid = row.BLOCKING_SID
        end
        if row.SQL_ID then
            sql_id = row.SQL_ID
        end
        if row.BLOCKED_SID then
            blocked_sid = row.BLOCKED_SID
        end
        if row.BLOCKED_USERNAME then
            blocked_username = remove_special_chars(row.BLOCKED_USERNAME)
        end
        if row.BLOCKED_MACHINE then
            blocked_machine = remove_special_chars(row.BLOCKED_MACHINE)
        end
        --for simple logging purposes
        logfile = io.open("blockingslog.csv", "a")
        io.output(logfile)
        io.write(blocking_sid)
        io.write(",")
        io.write(sql_id)
        io.write(",")
        io.write(blocked_sid)
        io.write(",")
        io.write(blocked_username)
        io.write(",")
        io.write(blocked_machine)
        io.write("\n")
        io.close(logfile)

        blocker = blocking_sid.."-"..sql_id
        if not setContains(blockers, blocker) then
            addToSet(blockers, blocker)
            set_start_time(blocker)
        end

        perceive_blockings(blocker, blocked_sid, blocked_username, blocked_machine) 
        row = cur:fetch (row, "a")
    end
    print(string.format("Current blockings: %s", numrows))
    cur:close() 

    --check if alerts needed
    totalblockers = 0
    for k,v in pairs(blockers) do
        totalblockers = totalblockers + 1
        need_alert_bool = check_need_alert(k)
        time_blocked = check_time_blocked(k)
        users_blocked = check_users_blocked(k)

        if (need_alert_bool) then
            addToSet(need_alerts, k)
            time_blocked_mappings[k] = time_blocked
            users_blocked_mappings[k] = users_blocked
        end
    end
    print(string.format("Total blockers found: %s", totalblockers))

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
            --for simple logging purposes
            logfile = io.open("alertslog.txt", "a")
            io.output(logfile)
            local ts = os.time()
            io.write(os.date('Timestamp: %Y-%m-%d %H:%M:%S\n', ts))
            io.write(msg_body)
            io.close(logfile)
        end
    end

    print("end of reasoning cycle\n")
    socket.sleep(30)
end

