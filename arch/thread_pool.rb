require 'socket'
require 'thread'
require_relative '../common'

module FTP
  class ThreadPool
    include Common

    CONCURRENCY = 25

    def run
      Thread.abort_on_exception = true
      threads = ThreadGroup.new

      CONCURRENCY.times do
        threads.add spawn_thread
      end

      sleep
    end

    def spawn_thread
      Thread.new do
        loop do
          client = @control_socket.accept
          handler = CommandHandler.new(self)
          request = client.gets(CRLF+CRLF)
          client.write handler.handle(request)
          #respond handler.handle(request)
          client.close
        end
      end
    end
  end
end

server = FTP::ThreadPool.new(4481)
server.run
