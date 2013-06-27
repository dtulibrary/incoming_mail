require 'incoming_mail'
require 'incoming_mail/log_formatter'

namespace :incoming_mail do
  desc "Fetch mails once"
  task :once => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/incoming_mail.log")
    Rails.logger.formatter = IncomingMail::LogFormatter.new
    IncomingMail.fetch
  end

  desc "Fetch mail in loop"
  task :loop => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/incoming_mail.log")
    Rails.logger.formatter = IncomingMail::LogFormatter.new
    IncomingMail.fetch_loop
  end
end
