#!/usr/local/bin/ruby

require 'class/oml_book'

class OmlResvBook < OmlBook
	
	def initialize(row1, row2)
		# 「取消選択画面（各取消ボタンがある画面）」のtrの1行目・2行目をもらって、値を初期化
		# フォーマット:
			#取消ボタン
			#No
			#書名
			#受取館／連絡区分
			#受付日付／種別
			#受付番号／書誌ＩＤ
			#状態／取置期限
		tds = row1.search("td")
		
		@no = clean(tds[1].inner_text)
		@book_name = clean(tds[3].inner_text)
##		@reserved = clean(tds[9].inner_text)
##		@reserve_no = clean(tds[7].inner_text)
##		@status = clean(tds[10].inner_text)
		
#		tds = row2.search("td")
##		@book_id = clean(tds[8].inner_text)
##		@hold_limit = clean(tds[11].inner_text)
	end
	
	def is_status_hold
		# return (Kconv.kconv(@status, Kconv::UTF8) == "取置き中")
		return (@hold_limit != "")
	end
	
	# 独自のgetter
	attr_reader :reserved, :reserve_no, :status, :hold_limit
end
