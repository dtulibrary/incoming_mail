class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

class IncomingMail::LogFormatter
  def call(severity, time, progname, msg)
    formatted_time = time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
    sprintf("%5d %s %-5s %5d %s\n", $$, formatted_time, severity, msg.strip)
  end
end
