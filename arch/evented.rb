require 'socket'
require_relative '../common'

module FTP
  class Evented
    CHUNK_SIZE=1024*16
    include Common

    class Connection
      include Common

      attr_reader :client

      def initialize(io)
        @client = io
        @request, @response = "",""
        @hander = CommandHandler.new(self)

        # @response = "220 OHAI"+CRLF
        # on_writable
      end

      def on_data(data)
        #pp "on data #{@client}"
        #pp #{@client}
        @request << data

        #if @request.end_with?(CRLF)
        if @request.end_with?(CRLF)
          @response = @hander.handle(@request)
          @request  = ""
        end
      end

      def on_writable #try to write
        #pp "on writable #{@client}"
        bytes = client.write_nonblock(@response)
        @response.slice!(0,bytes)
        @response.empty?
      end

      def monitor_for_reading?
        true
      end

      def monitor_for_writing?
        !(@response.empty?)
      end
    end

    def run
      # @control_socket means connection socket to accept
      # pair of {fd, connection}
      @handles = {}

      loop do
        to_read = @handles.values.select(&:monitor_for_reading?).map(&:client)
        to_write = @handles.values.select(&:monitor_for_writing?).map(&:client)

        readables,writables = IO.select(to_read + [@control_socket],to_write)

        readables.each do |socket|
          # some one try to connect
          if socket == @control_socket
            io = @control_socket.accept
            #pp "accepted #{io}"
            connection = Connection.new(io)
            @handles[io.fileno] = connection
          else
            # some one try to write
            connection = @handles[socket.fileno]

            begin
              data = socket.read_nonblock(CHUNK_SIZE)
              connection.on_data(data)
            rescue Errno::EAGAIN
            rescue EOFError
              @handles.delete(socket.fileno)
            end
          end
        end

        writables.each do |socket|
          connection = @handles[socket.fileno]
          if connection.on_writable
            @handles.delete(socket.fileno)
            socket.close
          end
        end
      end
    end
  end
end

server = FTP::Evented.new(4481)
server.run
