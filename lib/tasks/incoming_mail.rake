require 'incoming_mail'

namespace :incoming_mail do
  desc "Fetch mails once"
  task :once => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/incoming_mail.log")
    IncomingMail.fetch
  end

  desc "Fetch mail in loop"
  task :loop => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/incoming_mail.log")
    IncomingMail.loop_fetch
  end
end
