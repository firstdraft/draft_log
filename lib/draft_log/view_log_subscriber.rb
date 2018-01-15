require "active_support"

module DraftLog
  class ViewLogSubscriber < ActiveSupport::LogSubscriber

    def render_template(event)
      Thread.current[:view_log_payload] = event.payload
    end

  end
end
