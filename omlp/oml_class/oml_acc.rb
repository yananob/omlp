#!/usr/local/bin/ruby

require 'class/mydb'
require 'kconv'

class OmlAcc
	
	PASS_KEYS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
	
	def initialize(mail, seq)
		my = MyDB.new
		
		@mail = mail
		@seq = seq
		@pass_key = Hash.new
		
		if (@seq == "")
			return
		end
		
		# get user's data
		sql = "select * " +
		      "  from oml_user_ml_m " +
		      " where mail = ? " +
		      "   and seq = ? "
		res = my.query(sql, [@mail, @seq])
		row = res.fetch_row()
		@oml_id = row[2]
		@oml_pwd = row[3]
		@memo = Kconv.kconv(row[4], Kconv::UTF8)
		@crawled = row[5]
		
		# passkeyのHashを作成
		sql_pk = "select * " +
		         "  from oml_user_passkey_m " +
		         " where mail = ? " +
		         "   and seq = ? "
		res_pk = my.query(sql_pk, [@mail, @seq])
		res_pk.each do |row_pk|
#			p row_pk
#			print Kconv.kconv(row_pk[2].to_s, Kconv::UTF8) + "<br>\n"
#			@pass_key.store(Kconv.kconv(row_pk[2], Kconv::UTF8), row_pk[3])
			@pass_key.store(row_pk[2].to_s, row_pk[3])
		end
	end
	
	def add
		my = MyDB.new
		
		# 最大のseqを取得
		sql = "select max(seq) + 1 " +
		      "  from oml_user_ml_m " +
		      " where mail = ? "
		res_seq = my.query(sql, [@mail])
		row_seq = res_seq.fetch_row
		@seq = row_seq[0]
		# 既存カードがない場合
		if (!@seq)
			@seq = "1"
		end
		
		sql = "insert into oml_user_ml_m values ( " +
		      "     ?, ?, ?, ?, ?, null " +
		      " ) "
		my.query(sql, [@mail, @seq, @oml_id, @oml_pwd, @memo])
		
		add_passkey_m(my)
	end
	
	def add_passkey_m(my)
		@pass_key.each_pair do |key, value|
			sql = "insert into oml_user_passkey_m values ( " +
			      "     ?, ?, ?, ? " +
			      " ) "
			my.query(sql, [@mail, @seq, key, value])
		end
	end
	
	def update
		my = MyDB.new
		
		sql = "update oml_user_ml_m set " +
		      "     oml_id = ? " +
		      "    ,oml_pwd = ? " +
		      "    ,memo = ? " +
		      " where mail = ? " +
		      "   and seq = ? "
		my.query(sql, [@oml_id, @oml_pwd, @memo, @mail, @seq])
		
		# 削除してから全てinsert
		remove_passkey_m(my)
		add_passkey_m(my)
	end
	
	def remove
		my = MyDB.new
		
		sql = "delete from oml_user_ml_m " +
		      " where mail = ? " +
		      "   and seq = ? "
		my.query(sql, [@mail, @seq])
		
		remove_passkey_m(my)
	end
	
	def remove_passkey_m(my)
		sql = "delete from oml_user_passkey_m " +
		      " where mail = ? " +
		      "   and seq = ? "
		my.query(sql, [@mail, @seq])
	end
	
	def set_cgi_param(cgi)
		# 値セット
		@oml_id = cgi['oml_id']
		@oml_pwd = cgi['oml_pwd']
		@memo = cgi['memo']
		@pass_key = Hash.new
		PASS_KEYS.each do |key|
			@pass_key.store(key, cgi['pass_key_' + key])
		end
		
		# 入力チェック
		check_blank(@oml_id, "図書館カード番号")
		check_blank(@oml_pwd, "図書館パスワード")
		# メモは空白でもOK
		@pass_key.each_pair do |key, value|
			check_blank(value, "暗号カード番号[" + key + "]")
		end
	end
	
	attr_reader :mail, :seq, :oml_id, :oml_pwd, :memo, :crawled, :pass_key
	attr_writer :crawled
end
