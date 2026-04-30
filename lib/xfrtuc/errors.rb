# frozen_string_literal: true

module Xfrtuc
  module HTTP
    class Error < StandardError; end

    class ClientError < Error; end
    class BadRequest < ClientError; end
    class NotFound < ClientError; end
    class Conflict < ClientError; end
    class Gone < ClientError; end

    class ServerError < Error; end
    class ServiceUnavailable < ServerError; end

    class ConnectionResetError < Error; end
    class SocketError < Error; end
  end
end
