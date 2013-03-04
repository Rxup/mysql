local SQLConf = {} 
local DB = {}

SQLConf.Host = "127.0.0.1" 
SQLConf.Username = "gmod" 			
SQLConf.Password = "----" 	
SQLConf.Database_name = "gmod" 
SQLConf.Database_port = 3306

if file.Exists("lua/bin/gmsv_mysqloo_linux.dll", "LUA") or file.Exists("includes/modules/gmsv_mysqloo_i486.so", "LUA") or file.Exists("lua/bin/gmsv_mysqloo_win32.dll", "LUA") then
	MsgN("MySqlOO files found, trying to include them!\n")
	require("mysqloo")
end

local STATUS_READY
local STATUS_WORKING
local STATUS_OFFLINE
local STATUS_ERROR

DB.MySQLDB = nil

function DB.ConnectToMySQL(host, username, password, database_name, database_port)
	if not mysqloo then
		require('mysqloo')
	end
	if not mysqloo then
		MsgN("MySQL modules aren't installed properly!\n")
	else
		STATUS_READY	= mysqloo.DATABASE_CONNECTED
		STATUS_WORKING	= mysqloo.DATABASE_CONNECTING
		STATUS_OFFLINE	= mysqloo.DATABASE_NOT_CONNECTED
		STATUS_ERROR	= mysqloo.DATABASE_INTERNAL_ERROR
		
		local databaseObject = mysqloo.connect(host, username, password, database_name, database_port)
		
		databaseObject.onConnected = function()
			MsgN("----->Establishing connection to Database "..host.."\n")
			hook.Call("mysql_connect",nil,databaseObject)
		end
		
		databaseObject.onConnectionFailed = function(msg)
			databaseObject.automaticretry = true
			timer.Simple(30, function()
				databaseObject:connect()
			end);
			MsgN("MySQL Error: Connection failed! "..tostring(err).."\n")
			hook.Call("mysql_connect_fail",nil,databaseObject,msg)
		end
		databaseObject:connect() 
		DB.MySQLDB = databaseObject
	end
end
DB.ConnectToMySQL(SQLConf.Host, SQLConf.Username, SQLConf.Password, SQLConf.Database_name, SQLConf.Database_port)

function CheckStatus()
	if (not DB.MySQLDB or DB.MySQLDB.automaticretry) then return; end
	local status = DB.MySQLDB:status();
	if (status == STATUS_WORKING or status == STATUS_READY) then
		return;
	--[[
	elseif (status == STATUS_ERROR) then
		notifyerror("The database object has suffered an inernal error and will be recreated.")
		local pending = DB.MySQLDB.pending;
		DB.ConnectToMySQL(SQLConf.Host, SQLConf.Username, SQLConf.Password, SQLConf.Database_name, SQLConf.Database_port)
		DB.MySQLDB.pending = pending;
	]]
	else
		MsgN("The server has lost connection to the database. Retrying...")
		DB.MySQLDB:connect()
	end
end

timer.Create("SourceBans.lua - Status Checker", 60, 0, CheckStatus)
