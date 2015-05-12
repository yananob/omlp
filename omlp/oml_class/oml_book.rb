#!/usr/local/bin/ruby

require 'rubygems'

class OmlBook
	
	# HTML中のゴミを除く
	def clean(str)
		str.gsub!("&nbsp;", "")
		
		str
	end
	
	# 共通のgetter
	attr_reader :no, :book_name, :book_id
end
