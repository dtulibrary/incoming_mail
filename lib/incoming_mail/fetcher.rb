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
      $incoming_mail_run = true
      $incoming_mail = false

      # Setup signal handlers
      Signal.trap("TERM") { |sig| terminate_handler(sig) }
      Signal.trap("HUP") { |sig| terminate_handler(sig) }
      Signal.trap("QUIT") { |sig| terminate_handler(sig) }
      # Get the process to check mails
      Signal.trap("USR1") { |sig| process_mail_handling(sig) }

      start_imap

      # Process the inbox once before we start to loop
      Rails.logger.info "Process mail box before loop"
      process

      Rails.logger.info "Starting mail processing loop"
      while $incoming_mail_run do
        process_thread = Thread.start do
          @imap.idle do |resp|
            if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
              Rails.logger.info "New messages"
              $incoming_mail = true
            end
          end
        end

        Rails.logger.info "Waiting for 20 minutes or flag"
        sleep_break(1200)  # Every 20 minutes we do a manual check

        $incoming_mail = false
        @imap.idle_done
        process_thread.join
        process if $incoming_mail_run
      end

      finish
      Rails.logger.info "Mail loop finished"
    end

    def process
      check_processed_mailbox(@config['processed_mailbox'])
      @imap.select @config['mailbox']
      msg_ids = @imap.uid_search(["ALL"])
      Rails.logger.info("Processing #{msg_ids.count} messages")
      unless msg_ids.empty?
        msg_ids.each do |msg_id|
          begin
            mail = Mail.new(@imap.uid_fetch(msg_id, 'RFC822').first.attr['RFC822'])
            if IncomingMailController.receive(mail)
              @imap.uid_copy(msg_id, @processed_mailbox) if @processed_mailbox
              @imap.uid_store msg_id, '+FLAGS', [:Deleted]
            end
          rescue StandardError => e
            Rails.logger.info "Mail process -> " + e.message
          end
        end
      end
      # Delete mails marked as deleted
      @imap.expunge()
    end
  
    def sleep_break( seconds ) # breaks after n seconds or after interrupt
      while (seconds > 0)
        sleep(1)
        seconds -= 1
        break unless $incoming_mail_run
        break if $incoming_mail
      end
    end

    def terminate_handler(signo)
      Rails.logger.info "Got signal #{signo} - end run"
      $incoming_mail_run = false
    end

    def process_mail_handler(signo)
      Rails.logger.info "Got signal #{signo} - processing mail"
      $incoming_mail = true
    end

  end
end
