require 'socket'
require_relative '../common'

module FTP
  class ThreadPerConnection
    include Common

    def run
      Thread.abort_on_exception = true

      loop do
        @client = @control_socket.accept

        Thread.new do
          # child thread
          respond "220 OHAI"

          handler = CommandHandler.new(self)
          loop do
            request = @client.gets(CRLF)

            if request
              respond handler.handle(request)
            else
              @client.close
              break
            end
          end
        end

        # parent thread?
      end
    end
  end
end

server = FTP::ThreadPerConnection.new(4481)
server.run
