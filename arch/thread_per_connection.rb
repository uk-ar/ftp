require 'socket'
require_relative '../common'

module FTP
  class ThreadPerConnection
    include Common

    def run
      Thread.abort_on_exception = true

      loop do
        client = @control_socket.accept

        Thread.new(client) do |client|
          # child thread

          handler = CommandHandler.new(client)
          request = client.gets(CRLF+CRLF)
          client.write handler.handle(request)
          #respond handler.handle(request)

          client.close
        end

        # parent thread?
      end
    end
  end
end

server = FTP::ThreadPerConnection.new(4481)
server.run
