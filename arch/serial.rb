require 'socket'
require_relative '../common'

module FTP
  class Serial
    include Common

    def run
      loop do
        @client = @control_socket.accept

        handler = CommandHandler.new(self)
        request = @client.gets(CRLF+CRLF)
        respond handler.handle(request)
        @client.close
      end
    end
  end
end

server = FTP::Serial.new(4481)
server.run
