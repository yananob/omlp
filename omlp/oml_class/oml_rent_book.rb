#!/usr/local/bin/ruby

require 'class/oml_book'

class OmlRentBook < OmlBook
	
	def initialize(row1, row2)
		# trの1行目・2行目をもらって、値を初期化
		# フォーマット:
			#延長ボタン・フォーム
			#No
			#書名
			#貸出館／延長回数
			#返却期限／延長日
			#資料コード（書誌IDではない）／予約有無
		tds = row1.search("td")
		td_vals = (tds[0]/"form/input")
		td_vals.each do |val|
			if (val.attributes["name"] == "BIBID")
				@book_id = clean(val.attributes["value"])
				break
			end
		end
		@no = clean(tds[1].inner_text)
		@book_name = clean(tds[3].inner_text)
		date = ParseDate::parsedate(clean(tds[4].inner_text))
		@ret_limit = Date.new(date[0], date[1], date[2])
		
#		tds = row2.search("td")
#		@ext_cnt = clean(tds[0].inner_text).to_i
#		if (@ext_cnt == 0)
#			@extended = " "
#		else
#			@extended = "済"
#		end
		@extended = tds[5].inner_text
		@extended_date = " "
#		date_s = clean(tds[1].inner_text)
#		if (date_s != "")
#			date = ParseDate::parsedate(clean(tds[1].inner_text))
#			@extended_date = Date.new(date[0], date[1], date[2])
#		end
		@extended_date = " "
#		@exist_resv = clean(tds[2].inner_text)
		if (@exist_resv == "予約有り")
			@exist_resv = "有"
		else
			@exist_resv = " "
		end
		@exist_resv = " "
	end
	
	# 延長可能か？
	def extendable?
		if ((@ext_cnt == 0) && (@exist_resv == " "))
			return true
		else
			return false
		end
	end
	
	# 返却期限の2日前か？ TODO: ユーザごとに設定できるように
	def near_limit?
		if (Date.today >= ret_limit - 2)	# TODO★★★★★★★★★
			return true
		else
			return false
		end
	end
	
	# 独自のgetter
	attr_reader :ret_limit, :ext_cnt, :extended, :extended_date, :exist_resv
end
