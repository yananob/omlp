#!/usr/local/bin/ruby

require 'class/oml_book'

class OmlSearchBook < OmlBook
	
	def initialize(row1)
		# trの1行目・2行目をもらって、値を初期化
		# フォーマット:
			#延長ボタン・フォーム
			#No
			#書名
		# 			<TR VALIGN=baseline>
		# 				<TD ALIGN="center" WIDTH=50><STRONG>Ｎｏ.</STRONG></TD>
		# 				<TD><STRONG>タイトル||著者||出版者||出版年||分類</STRONG></TD>
		# 			<TR VALIGN=baseline>
		# 				<TD ALIGN="center"><STRONG>1.</STRONG></TD>
		# 				<TD              ><A HREF="/cgi-bin/internet/opi_103.cgi?KY_GNO=102&KY_LANG=J&KY_BUTTON=01&NEW=&HIS=100&ORDER=syear&SORT=02&L=20&SS=1&S1=T%3ASEARCH&S2=&S3=&S4=&S5=&SEARCH1=%A1%A1%B8%A1%A1%A1%BA%F7%A1%A1&K0=SEARCH&L0=+&I0=T&CT1=1&CT2=1&CT3=1&AJ=&LOC=&Y1=&Y2=&CB=1&NUM=1&MAX=457" ><STRONG>実践ユーザビリティテスティング -「利用品質」を忘れていませんか-(IT Architects&#39;&#39; Archive)∥キャロル・M.バーナム/著∥翔泳社∥2007.8∥549.86◇549.86◇007.63</STRONG></A></TD></TR>
		
		tds = row1.search("td")
		@no = clean(tds[0].inner_text)
		@book_name = clean(tds[1].inner_text)
	end
	
	# 独自のgetter
	attr_reader :ret_limit, :ext_cnt, :extended, :exist_resv
end
