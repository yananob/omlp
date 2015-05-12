#!/usr/local/bin/ruby

require 'cgi'
require 'cgi/session'
require 'class/exp_input'
require 'class/exp_other'

#DEBUG = true
DEBUG = false

MAIL_ADMIN	= "nicher@s310.xrea.com"

DIR_LOG		= "log"

def check_login(cgi)
	begin
		session = CGI::Session.new(cgi, 'new_session' => false)
	rescue ArgumentError  # if no old session
		raise OtherException, "ログインされていません。"
#		raise OtherException, "not logged in.", "login.rb"
	end
	# ユーザセッションがなければログインエラーに
	if (!session || session['mail'] == "")
		raise OtherException, "ログインされていません。: " + session.to_s
	end
	
	session
end

def dump(str)
	print Time.now.strftime("%Y/%m/%d %H:%M:%S") + "\t" + str + "\n"
end

def nullstr(str)
	if (!str)
		""
	else
		str
	end
end

# 入力チェック系
def check_blank(value, item_name)
	if (value == "")
		raise InputException, "[" + item_name + "]を入力してください。"
	end
end

# 記号などを省く（メルアドをファイル名に使ったり）
def replace_chars(str)
	str_rp = str.gsub(/[\.@]/, "")
	
	str_rp
end
