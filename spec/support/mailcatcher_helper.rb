# frozen_string_literal: true

require 'mailcatcher/api'
require 'faraday'

module MailCatcherHelper
  def mailcatcher_connection
    @mailcatcher_connection ||=
      Faraday.new(url: MailCatcher::API.config.server) do |faraday|
        faraday.adapter :net_http
      end
  end

  def mailcatcher_mailbox
    @mailcatcher_mailbox ||= MailCatcher::API::Mailbox.new
  end

  def mailcatcher_clear
    mailcatcher_connection.delete('/messages')
  end

  def mailcatcher_email(opts = {})
    mailcatcher_mailbox
      .messages(reload: true)
      .detect { |m| opts.all? { |key, value| m.send(key) == value } }
  end
end
