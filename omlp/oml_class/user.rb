#!/usr/local/bin/ruby

require 'class/mydb'
require 'class/oml_acc'
require 'class/exp_input'

class User
	
	def initialize(mail)
		
		@is_exist = false
		@mail = mail
		if (@mail == "")
			# 作るだけ
			return
		end
		
		# ユーザ情報取得
		select
	end
	
	def select
		my = MyDB.new
		
		sql = "select pwd, send_day, send_time " +
		      "  from oml_user_m " +
		      " where mail = ? "
		res = my.query(sql, [@mail])
		if (res.num_rows() != 1)
			# raise InputException, "ユーザ情報の取得に失敗: " + @mail
			# 同じアドレスのユーザが既存かをチェックするために、エラーにはしない
			return
		end
		row = res.fetch_row()
		@pwd = row[0]
		set_send_day(row[1])
		@send_time = row[2]
		
		@oml_acc = Hash.new
		sql = "select seq " +
		     "  from oml_user_ml_m " +
		     " where mail = ? " +
		     " order by seq "
		res = my.query(sql, [@mail])
		res.each {|row|
			@oml_acc.store(row[0], OmlAcc.new(@mail, row[0]))
		}
		
		@is_exist = true
	end
	
	def cert(try_pwd)
		if (@pwd != try_pwd)
			raise InputException, "メールアドレスまたはパスワードが誤っています。"
		end
	end
	
	def add(cgi)
		set_cgi_param(cgi)
		
		my = MyDB.new
		
		sql = "insert into oml_user_m values ( " +
		      "     ?, ?, ?, ? " +
		      " ) "
		my.query(sql, [@mail, @pwd, @send_day.join(","), @send_time])
	end
	
	def update(cgi)
		set_cgi_param(cgi)
		
		my = MyDB.new
		
		sql = "update oml_user_m set " +
		      "     pwd = ? " +
		      "    ,send_day = ? " +
		      "    ,send_time = ? " +
		      " where mail = ? "
		my.query(sql, [@pwd, @send_day.join(","), @send_time, @mail])
	end
	
	def remove
		my = MyDB.new
		
		sql = "delete from oml_user_m " +
		      " where mail = ? "
		my.query(sql, [@mail])
		
		# OMLアカウントも削除
		@oml_acc.each_pair do |key, acc|
			acc.remove
		end
	end
	
	def is_send_day(day)
		if (!@send_day)
			return false
		end
	
		# 配列に値があれば、送信日に該当
		(@send_day.index(day) != nil)
	end
	
	def set_send_day(str)
		@send_day = Array.new
		str.split(",").each do |day|
			@send_day.push(day)
		end
	end
	
	def set_cgi_param(cgi)
		@mail = cgi['mail']
		if (cgi['pwd'] != "")
			@pwd = cgi['pwd']
		end
		set_send_day(cgi.params['send_day'].join(","))
		@send_time = cgi['send_time']
	end
	
	def file_path_send
		file_base = DIR_LOG + "/" + replace_chars(@mail)
		
		file_base + ".send"
	end
	
	attr_reader :mail, :send_day, :send_time, :oml_acc, :is_exist
end
