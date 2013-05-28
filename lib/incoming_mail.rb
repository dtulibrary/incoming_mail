module IncomingMail
  require 'incoming_mail/railtie' if defined?(Rails)

  def self.fetch
    require 'incoming_mail/fetcher'
    mail = IncomingMail::Fetcher.new
    mail.fetch
  end

  def self.fetch_loop
    require 'incoming_mail/fetcher'
    mail = IncomingMail::Fetcher.new
    mail.fetch_loop
  end
end
