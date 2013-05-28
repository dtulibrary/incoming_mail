require 'incoming_mail'
require 'rails'
module IncomingMail
  class Railtie < Rails::Railtie
    railtie_name :incoming_mail

    rake_tasks do
      load "tasks/incoming_mail.rake"
    end
  end
end
