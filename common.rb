module FTP
  module Common
    CRLF="\r\n"
    def initialize(port=21)
      @control_socket = TCPServer.new(port)
      trap(:INT){exit}
    end
    def respond(response)
      @client.write(response)
    end

    class CommandHandler
      attr_reader :connection
      def initialize(connection)
        @connection = connection
      end
      def handle(data)
        <<~RESP
HTTP/1.1 200 OK

<html>
<body>
<p>Hello world</p>
</body>
</html>
        RESP
      end
    end
  end
end
#ftp -4 -A localhost 4481
#ls
#get serial.rb
