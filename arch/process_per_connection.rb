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
          handler = CommandHandler.new(self)
          request = @client.gets(CRLF+CRLF)
          respond handler.handle(request)
          @client.close
        end
        @client.close
        # parent process
        Process.detach(pid)
      end
    end
  end
end

server = FTP::ProcessPerConnection.new(4481)
server.run
