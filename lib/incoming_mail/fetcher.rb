require 'yaml'
require 'net/imap'
require 'openssl'
require 'mail'

module IncomingMail

  class Fetcher

    public

    def initialize
      @imap = nil
      @processed_mailbox = nil
      @latest_date = nil
      # Get configuration
      @config = YAML.load(File.open(Dir[Rails.root.join("config/incoming*mail*.yml")][0]))
    end

    def start_imap
      @imap = Net::IMAP.new @config['server'],
        :port => @config['port'],
        :ssl => @config['ssl']
      @imap.login(@config['user'], @config['password'])
      @imap.select @config['mailbox']
    end

    def check_processed_mailbox(mailbox)
      return unless(mailbox)
      time = Time.new
      newbox = "%s-%04d-%02d" % [mailbox, time.year, time.month]
      return if newbox == @processed_mailbox
      @processed_mailbox = newbox
      list = @imap.list("", @processed_mailbox)
      if list
        list.each do |box|
          return if(box.name == @processed_mailbox)
        end
      end
      @imap.create(@processed_mailbox)
    end

    def finish
      @imap.close
      @imap.disconnect
      @imap = nil
    end

    def fetch
      start_imap
      process
      finish
    end

    def fetch_loop
      $incoming_mail_run = 1
      # Setup signal handlers
      Signal.trap("USR1") do
        $incoming_mail_run = 0
      end
      Signal.trap("HUP") do
        $incoming_mail_run = 0
      end
      start_imap

      # Process the inbox once before we start to loop
      Rails.logger.info "Process mail box before loop"
      process

      Rails.logger.info "Starting mail processing loop"
      while $incoming_mail_run do
        Rails.logger.info "Incoming mail loop idle"
        @imap.idle do |resp|
          if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
            process
          end
        end
        sleep(1200)  # Every 20 minutes we do a manual check
        @imap.idle_done
        # Do a manual check, just in case things aren't working properly.
        Rails.logger.info "Process mail box - catch up"
        process if $incoming_mail_run
      end
      finish
    end

    def process
      check_processed_mailbox(@config['processed_mailbox'])
      @imap.select @config['mailbox']
      msg_ids = @imap.search(["ALL"])
      unless msg_ids.empty?
        msg_ids.each do |msg_id|
          begin
            mail = Mail.new(@imap.fetch(msg_id, 'RFC822').first.attr['RFC822'])
            if IncomingMailController.receive(mail)
              @imap.copy(msg_id, @processed_mailbox) if @processed_mailbox
              @imap.store msg_id, '+FLAGS', [:Deleted]
            end
          rescue StandardError => e
            Rails.logger.info "Mail process -> " + e.message
          end
        end
      end
      # Delete mails marked as deleted
      @imap.expunge()
    end
  
  end
end
