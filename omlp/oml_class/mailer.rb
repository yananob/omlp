#!/usr/local/bin/ruby

require 'email'
require 'kconv'

class Mailer
	
	def send(subject, mail_to, mail_string, attach_files)
		mail = AttachedEmail.new
		mail.smtpServer      = "localhost"
		
		mail['To'] = mail_to
		mail['From'] = "nicher@s310.xrea.com"
		mail['Subject'] = subject.mime_encode
		
		bl_body = Email.new
		bl_body['Content-Type'] = "Text/Plain; charset=ISO-2022-JP"
		bl_body << mail_string.tojis
		
		bl_attach = EncodedEmail.new
		for file in attach_files
			bl_attach['Content-Type'] = "text/html; name=\"" + file + ".html\""
#			bl_attach['Content-Type'] = "text/html; name=\"#{"添付Mail.rb".mime_encode}\""
			bl_attach['Content-transfer-encoding'] = "base64"
			bl_attach << open(file).read
		end
		 
		mail << bl_body << bl_attach
		mail.send
	end
end
