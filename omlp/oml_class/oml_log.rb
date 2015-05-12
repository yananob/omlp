#!/usr/local/bin/ruby

require 'kconv'
require 'class/common'
require 'class/mydb'
require 'class/oml_mecha'

class OmlLog
	
	def initialize(oml_acc)
		@oml_acc = oml_acc
		
		# ファイル名にするために、記号を除去（元の値を置換すると、大元の値を変えてしまうみたい）
		file_base = DIR_LOG + "/" + replace_chars(@oml_acc.mail) + "_" + @oml_acc.oml_id
		@file_path = Array.new
		@file_path[0] = file_base + ".resv"
		@file_path[1] = file_base + ".rent"
		@file_path_send = file_base + ".send"
		
		load_log
	end
	
	def load_log
		buf = Array.new
		for i in [0, 1] do
			buf[i] = ""
			# ログファイル内容の文字コード変換
			if (File.exist?(@file_path[i]))
				f = open(@file_path[i], "r")
				while line = f.gets
					buf[i] += Kconv.kconv(line, Kconv::UTF8)
				end
				f.close
			end
		end
		
		mecha = OmlMecha.new
		@books_resv = mecha.parse_resv(buf[0])
		@books_rent = mecha.parse_rent(buf[1])
	end
	
	# ログ巡回
	def crawl
		mecha = OmlMecha.new
		page = mecha.crawl_resv(@oml_acc)
		log_resv = page.body
		page = mecha.crawl_rent(@oml_acc)
		log_rent = page.body
		
		save_log(log_resv, log_rent)
		
		load_log
	end
	
	# 予約キャンセル
	def cancel_resv(no)
		mecha = OmlMecha.new
		page = mecha.cancel_resv(@oml_acc, no)
		log_resv = page.body
		
		save_log(log_resv, nil)
		
		load_log
	end
	
	# 貸し出し延長
	def extend(no)
		mecha = OmlMecha.new
		page = mecha.extend(@oml_acc, no)
		log_rent = page.body
		
		save_log(nil, log_rent)
		
		load_log
	end
	
	# ログ保存
	def save_log(log_resv, log_rent)
		saved = false
		
		if (log_resv)
			f = open(@file_path[0], "w")
			f.write(log_resv)
			f.close
			saved = true
		end
		if (log_rent)
			f = open(@file_path[1], "w")
			f.write(log_rent)
			f.close
			saved = true
		end
		
		if (!saved)
			return
		end
		
		my = MyDB.new
		
		# 最終取得日を更新
		sql = "update oml_user_ml_m set " +
		      "    crawled = now() " +
		      " where mail = ? " +
		      "   and oml_id = ? "
		my.query(sql, [@oml_acc.mail, @oml_acc.oml_id])
		
		# ToD: ここで、oml_acc.crawledを更新してないから、「ログを手動更新」しても、更新日時が変わらないっぽい
		@oml_acc.crawled = Time.now
		
	end
	
	# 取り置き中書籍数
	def books_hold_cnt
		cnt = 0
		@books_resv.each_pair do |no, oml_book|
			if (oml_book.is_status_hold)
				cnt += 1
			end
		end
		
		cnt
	end
	
	# 返却期限が近い書籍数
	def books_near_limit
		cnt = 0
		@books_rent.each_pair do |no, oml_book|
			if (oml_book.near_limit?)
				cnt += 1
			end
		end
		
		cnt
	end
	
	attr_reader :books_resv, :books_rent, :file_path_send
end
