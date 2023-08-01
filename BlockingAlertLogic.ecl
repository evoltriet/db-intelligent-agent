%
% Blocking alert logic
%


need_alert(Blocker) :-
	condition1(Blocker);
	condition2(Blocker);
	condition3(Blocker);
	condition4(Blocker).

	
condition1(Blocker) :-
	blocked(Blocked, Blocker),
	machine(Machine, Blocked),
	username(Username, Blocked),
	substring(Machine,0,3,_,"wtx"),
	(\+ substring(Username,_,3,0,"_db")),
	time_blocked(TimeBlocked, Blocker),
	TimeBlocked > 30,
	users_blocked(UsersBlocked, Blocker),
	UsersBlocked >= 3.
	
condition2(Blocker) :-
	blocked(Blocked, Blocker),
	machine(Machine, Blocked),
	username(Username, Blocked),
	substring(Machine,0,3,_,"wtx"),
	(\+ substring(Username,_,3,0,"_db")),
	time_blocked(TimeBlocked, Blocker),
	TimeBlocked > 300,
	users_blocked(UsersBlocked, Blocker),
	UsersBlocked > 0.
	
condition3(Blocker) :-
	time_blocked(TimeBlocked, Blocker),
	TimeBlocked > 3600,
	users_blocked(UsersBlocked, Blocker),
	UsersBlocked > 0.
	
condition4(Blocker) :-
	time_blocked(TimeBlocked, Blocker),
	TimeBlocked > 600,
	users_blocked(UsersBlocked, Blocker),
	UsersBlocked > 50.
	
	
time_blocked(TimeBlocked, Blocker) :-
	start(Start, Blocker),
	currtime(Now),
	TimeBlocked is Now - Start.
	
users_blocked(UsersBlocked, Blocker) :-
	findall(., blocked(Blocked, Blocker), Ls),
   	length(Ls, Count),
	UsersBlocked is Count.
	

	
	
