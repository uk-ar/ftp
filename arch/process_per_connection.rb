require 'socket'
require_relative '../common'

module FTP
  class ProcessPerConnection
    include Common

    def run
      loop do
        @client = @control_socket.accept

        pid = fork do
          # child process
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

        # parent process
        Process.detach(pid)
      end
    end
  end
end

server = FTP::ProcessPerConnection.new(4481)
server.run
