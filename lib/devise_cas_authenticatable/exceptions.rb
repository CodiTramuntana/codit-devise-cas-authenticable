# frozen_string_literal: true

# Thrown when a user attempts to pass a CAS ticket that the server
# says is invalid.
class InvalidCasTicketException < RuntimeError
  attr_reader :ticket

  def initialize(ticket, msg = nil)
    super(msg)
    @ticket = ticket
  end
end
