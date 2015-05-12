#!/usr/local/bin/ruby

require 'rubygems'
require 'hpricot'
require 'mechanize'
require 'jcode'
require 'kconv'
require 'class/common'
require 'class/oml_acc'
require 'class/oml_resv_book'
require 'class/oml_rent_book'
require 'class/exp_input'

$KCODE = 'u'			# UTF-8

class OmlMecha
	
	def initialize
		@agent = WWW::Mechanize.new
		@agent.user_agent_alias = 'Windows IE 6'
		@agent.follow_meta_refresh = true
	end
	
	# クロール系は、いずれもpageを返すこととする
	def crawl_login(oml_acc)
		buf = Array.new
#		page = @agent.get('https://www.oml.city.osaka.jp/cgi-bin/internet/opi_500.cgi?KY_GNO=000&KY_LANG=J&KY_BUTTON=01&')
		page = @agent.get('https://web.oml.city.osaka.lg.jp/webopac_i_ja/login.do?url=ufisnd.do%3Fredirect_page_id%3D13')
		
		# input card no
#		form = page.forms.with.name("MAIN").first
		form = page.forms.with.name("comidfform").first
#		form.CARDNUM = oml_acc.oml_id
		form.userid = oml_acc.oml_id
#		page = @agent.submit(form)
		
		# input password
#		form = page.forms.with.name("MAIN2").first
#		if (!form)
#			raise InputException, "[図書館カード番号]に誤りがあります。"
#		end
#		form.PASWD = oml_acc.oml_pwd
		form.password = oml_acc.oml_pwd
		page = @agent.submit(form)
		
		# 空ページを再送信
		form = page.forms.with.name("ufisndform").first
		page = @agent.submit(form)
		
		# input passkey
#		form = page.forms.with.name("MAIN").first
		# いったんメニュー表示。不要かも。
		page = @agent.get('https://web.oml.city.osaka.lg.jp/webopac_i_ja/asklst.do')
		if (!form)
#			raise InputException, "[図書館パスワード]に誤りがあります。"
			raise InputException, "[図書館カード番号][図書館パスワード]に誤りがあります。"
		end
#		key_used = Hash.new		# 使ったキー（間違ってるときの通知用）
#		for i in [1, 2]
#			key = form.field("PASS_KIND" + i.to_s)				# 画面キー値
#			key_value = Kconv.kconv(key.value, Kconv::UTF8)		# 画面のキー値（EUC）を変換
##			print "KEY" + i.to_s + ": " + key_value + "\n"
#			key_han = key_value.tr('Ａ-Ｚ', 'A-Z')				# 全角のキー値を半角に変換
#			form.field("PASS_KEY" + i.to_s).value = oml_acc.pass_key[key_han]	# 画面値にセット
##			print "PASS" + i.to_s + ": " + oml_acc.pass_key[key_han] + "<br>\n"
#			key_used.store(i, key_han)
#		end
#		# 予約状況を見る（ひとまず認証チェック用）
#		page = @agent.submit(form, form.buttons.with.name("BUTTON1").first)
#		
#		form = page.forms[1]
#		if (!form)
#			raise InputException, "[暗号カード番号[" + key_used[1] + "]または[" + key_used[2] + "]]に誤りがあります。"
#		end
		
		page
	end
	
	def crawl_resv(oml_acc)
#		page = crawl_login(oml_acc)
#		# この時点で、予約状況のページを表示済み
#		
		# 予約取消画面へ（ログ解析はこちらの内容を使う）
#		form = page.forms[2]
#		if (form)
#			page = @agent.submit(form)
#		end
		
		page = @agent.get('https://web.oml.city.osaka.lg.jp/webopac_i_ja/rsvlst.do')
		
		page
	end
	
	# 予約取り消し
	def cancel_resv(oml_acc, no)
		page = crawl_resv(oml_acc)
		books_resv = parse_resv(page.body)
		
		# 書誌IDが一致するFormを探す
		page.forms.each do |form|
			if (form.has_field?("BIBID") && (form.BIBID = books_resv[no].book_id))
				# 取り消す
				page = @agent.submit(form)
				break
			end
		end
		
		# 確認画面で「取り消す」
		form = page.forms[0]
		page = @agent.submit(form)
		
		# 予約取消画面へ（戻る）
		form = page.forms[0]
		page = @agent.submit(form)
		
		page
	end
	
	def crawl_rent(oml_acc)
#		page = crawl_login(oml_acc)
#		
#		# 貸出状況を見る
#		form = page.forms[1]
#		page = @agent.submit(form)
#		
#		# 貸出館選択
#		# choise abeno ml
##		form = page.forms.action("/cgi-bin/internet/opi_530.cgi").first
#		form = page.forms[2]
#		if (form)
#			page = @agent.submit(form)
#		end
		
		page = @agent.get('https://web.oml.city.osaka.lg.jp/webopac_i_ja/lenlst.do')
		
		page
	end
	
	# 貸し出し延長
	def extend(oml_acc, no)
		page = crawl_rent(oml_acc)
		books_rent = parse_rent(page.body)
		
		# 書誌IDが一致するFormを探す
		page.forms.each do |form|
			if (form.has_field?("BIBID") && (form.BIBID = books_rent[no].book_id))
				# print "***ID: " + books_rent[no].book_id
				# 延長
				page = @agent.submit(form)
				break
			end
		end
		
		page
	end
	
	def parse_resv(body)
		books_resv = Hash.new
		
		if (body == "")
			return books_resv
		end
		
		doc = Hpricot(body.toutf8)
		
		# ほしい解析情報
		# ※タグを変換して、セレクタで見分けやすくする
		tables = (doc/"table")
		if (!tables[1])
			return books_resv
		end
		trs = tables[1].search("tr")
		idx = 1		# 最初のヘッダは捨てる
		while (idx < trs.length)
			# 2行のうち1行目をログ出力
			oml_book = OmlResvBook.new(trs[idx], trs[idx + 1])
			books_resv.store(oml_book.no, oml_book)
			
			idx += 2
		end
		
		books_resv
	end
	
	def parse_rent(body)
		books_rent = Hash.new
		
		if (body == "")
			return books_rent
		end
		doc = Hpricot(body.toutf8)
		
		tables = (doc/"table")
		# 2007/11/05: 追加。貸し出し中がない場合にエラーになるみたい
		if (!tables[1])
			return books_rent
		end
		trs = tables[1].search("tr")
		idx = 1		# 最初のヘッダは捨てる
		while (idx < trs.length)
			# 2行のうち1行目をログ出力
			oml_book = OmlRentBook.new(trs[idx], trs[idx + 1])
			books_rent.store(oml_book.no, oml_book)
			
			idx += 2
		end
		
		books_rent
	end
	
	def search(keyword)
		# 
		# form[1].K0
		# submit("SEARCH1")
		# 
		# table[4]
		# 		<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=5>
		# 			<TR VALIGN=baseline>
		# 				<TD ALIGN="center" WIDTH=50><STRONG>Ｎｏ.</STRONG></TD>
		# 				<TD><STRONG>タイトル||著者||出版者||出版年||分類</STRONG></TD>
		# 			<TR VALIGN=baseline>
		# 				<TD ALIGN="center"><STRONG>1.</STRONG></TD>
		# 				<TD              ><A HREF="/cgi-bin/internet/opi_103.cgi?KY_GNO=102&KY_LANG=J&KY_BUTTON=01&NEW=&HIS=100&ORDER=syear&SORT=02&L=20&SS=1&S1=T%3ASEARCH&S2=&S3=&S4=&S5=&SEARCH1=%A1%A1%B8%A1%A1%A1%BA%F7%A1%A1&K0=SEARCH&L0=+&I0=T&CT1=1&CT2=1&CT3=1&AJ=&LOC=&Y1=&Y2=&CB=1&NUM=1&MAX=457" ><STRONG>実践ユーザビリティテスティング -「利用品質」を忘れていませんか-(IT Architects&#39;&#39; Archive)∥キャロル・M.バーナム/著∥翔泳社∥2007.8∥549.86◇549.86◇007.63</STRONG></A></TD></TR>
		# 			<TR VALIGN=baseline>
		# 				<TD ALIGN="center"><STRONG>2.</STRONG></TD>
		# 				<TD              ><A HREF="/cgi-bin/internet/opi_103.cgi?KY_GNO=102&KY_LANG=J&KY_BUTTON=01&NEW=&HIS=100&ORDER=syear&SORT=02&L=20&SS=1&S1=T%3ASEARCH&S2=&S3=&S4=&S5=&SEARCH1=%A1%A1%B8%A1%A1%A1%BA%F7%A1%A1&K0=SEARCH&L0=+&I0=T&CT1=1&CT2=1&CT3=1&AJ=&LOC=&Y1=&Y2=&CB=1&NUM=2&MAX=457" ><STRONG>実践的研究のすすめ -人間科学のリアリティ-∥小泉 潤二/編∥有斐閣∥2007.7∥007◇007◇002.7</STRONG></A></TD></TR>
		#
		# frame[0].form[4].submit
		# 
		# form[1].CARDNUM
		
		# password
		#
		# form[1].submit(first.button)
		
		# form[1].submit
		
		
		page = @agent.get('http://www.oml.city.osaka.jp/cgi-bin/internet/opi_100.cgi?KY_GNO=000&KY_LANG=J&KY_BUTTON=01&NEW=&')
		
		form = page.forms[1]
		form.K0 = keyword
		page = @agent.submit(form, form.buttons["SEARCH1"])
		
		doc = Hpricot(body.toutf8)
		
		tables = (doc/"table")
		trs = tables[4].search("tr")
		if (trs.length != 2)		# 1件目はヘッダ
			raise InputException, "検索結果が2件以上存在します: " + keyword
		end
		link = (trs/"td/a")
		print link.attributes("href")
	end
	
end
