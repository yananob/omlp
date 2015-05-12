#!/usr/local/bin/ruby

require 'mysql'
require 'class/common'

class MyDB
	
	def initialize
		@my = Mysql::new("localhost", "USERID", "PASSWORD", "INSTANCENAME")
	end
	
#	def getInstance
#		@my
#	end
	
	def statement(sql, param)
		ret = sql
		for prm in param
#			print prm
			# SQL文字のエスケープ
			prm.gsub!("'", "''")
			prm.gsub!("\\", "\\\\")
			prm.gsub!("%", "\%")
			prm.gsub!("_", "\_")
			ret.sub!("?", "'" + prm + "'")
		end
		
		ret
	end
	
	def query(sql, param)
		sql = statement(sql, param)
		
		if (DEBUG)
			print Time.now.to_s + "\t " + sql + "<br>\n"
		end
		
		@my.query(sql)
	end
end
