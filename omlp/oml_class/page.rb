#!/usr/local/bin/ruby

require 'erb'
include ERB::Util
require 'class/common'

class Page
	
	TEMPLATE_PATH = "template/"
	TEMPLATE_EXT = ".rhtml"
	
	def initialize
		@header_set = false
	end
	
	# メモ： bindingを引数でもらっていると、メソッド内で使用するbindingは引き継いだものになる。
	#        この場合、このメソッド内で定義した変数は、bindingには追加されない。
	def show(page, title, isshowmenu, binding)
		# 以下、テンプレートで使用するための変数
#		inc_menu = ""
#		if (isshowmenu)
#			inc_menu = File.read(TEMPLATE_PATH + "inc_menu" + TEMPLATE_EXT)
#		end
#		
#		print parse_header(title) + erb_result(page, binding) + inc_menu
		
#		@inc_menu = ""
#		if (isshowmenu)
#			@inc_menu = File.read(TEMPLATE_PATH + "inc_menu" + TEMPLATE_EXT)
#		end
		@isshowmenu = isshowmenu
		
#		@inc_header = parse_header(title)
		@page_title = title
		
		@inc_body = erb_result(page, binding)
		
		print parse_skelton
	end
	
	# 画面全体の構成
	# この中では、既に大元からもらってきたbindingは不要なので、引数なしで処理してる
	def parse_skelton
		erb_result("skelton", binding)
	end
	
	# showでのresult処理と分けて、変数がクリアされるのを避ける
	# http://www.druby.org/ilikeruby/d204.html の「注意」
#	def parse_header(title)
#		page_title = title
#		erb_head = ERB.new(File.read(TEMPLATE_PATH + "inc_header" + TEMPLATE_EXT))
#		
#		erb_head.result(binding)
#	end
	
	def show_error(exp)
	#	print "Content-Type:text/html\n\n"
	#	print "<br>\n"
	#	print "*** CGI Error List ***<br>"
	#	print "#{CGI.escapeHTML($!.inspect)}\n"
	#	$@.each {|x| print CGI.escapeHTML(x), "\n"}
	#	print exp.message + "<br>\n"
	#	print "<pre>\n"
	#	print exp.backtrace.join("<br>\n")
	#	print "</pre>\n"
	#	if (exp.page)
	#		print "<a href='" + exp.page + "'>click</a>\n";
	#	end
		
		message = exp.message
		backtrace = ""
#		if (DEBUG)
			backtrace = exp.backtrace.join("\n")
			backtrace.gsub!("/virtual/nicher", "HOME")
#		end
		
		show("error", "エラー", false, binding)
	end
	
	def redirect(page)
		redirect_url = page
		show("redirect", "画面遷移中", false, binding)
		exit
	end
	
	def set_header(cgi)
		if (!@header_set)
			print cgi.header("charset" => "utf-8")
			@header_set = true
		end
	end
	
	def erb_result(page, binding)
		erb = ERB.new(File.read(TEMPLATE_PATH + page + TEMPLATE_EXT))
		
		erb.result(binding)
	end
end
