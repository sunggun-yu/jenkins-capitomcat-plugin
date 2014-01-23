module Capitomcat
  class JenkinsOutput

    attr_reader :native

    def initialize(native = nil)
      @native = native
    end

    def logger
      @native.getLogger()
    end

    def write(obj)
      case obj
        when SSHKit::LogMessage then
          write_log_message(obj)
        else
          logger.print(blind_ansi_color(obj.to_s))
      end
    end

    alias :<< :write


    def write_log_message(log)
      message = blind_ansi_color(log.to_s)
      case message.verbosity
        when Logger::DEBUG, Logger::INFO
          logger.print(message)
        when Logger::WARN, Logger::ERROR
          @native.error(message)
        else
          @native.fatalError(message)
      end
    end

    def blind_ansi_color(message)
      return message.gsub(/\e\[(\d+)(;\d+)*m/, '')
    end
  end

end