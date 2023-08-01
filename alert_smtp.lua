-- load the smtp support
local smtp = require("socket.smtp")


function send_email (msg_body)
	from = "Blocking-Detection-IA"
	server = "example.mail.server.com"
	rcpt = {
	  "<example.receipent@example.com>"
	}
	mesgt = {
	  headers = {
	    subject = "IA Detected Blockings in Oracle DB"
	  },
	  body = msg_body
	}

	ok, err = smtp.send{
	  from = from,
	  rcpt = rcpt, 
	  source = smtp.message(mesgt),
	  server = server
	}

	if not ok then
		print("Error sending email: ", err) -- better error handling required
		--for simple logging purposes
        logfile = io.open("alertslog.txt", "a")
        io.output(logfile)
        local ts = os.time()
		io.write(os.date('Timestamp: %Y-%m-%d %H:%M:%S\n', ts))
		io.write("Error sending email: ")
        io.write(err)
        io.write("\n\n")
        io.close(logfile)
	end
end