require 'incoming_mail'

namespace :incoming_mail do
  desc "Fetch mails once"
  task :once => :environment do
    IncomingMail.fetch
  end

  desc "Fetch mail in loop"
  task :loop => :environment do
    IncomingMail.loop_fetch
  end
end
