require "draft_log/log_subscriber"
require "draft_log/add_extra_request_log_data"
require "awesome_print"

if defined? Rails
  require "draft_log/railtie"
  require 'draft_log/rails_ext/rack/logger'
end

module DraftLog
  module_function

  def setup
    remove_existing_log_subscriptions
    ActionController::Base.send :prepend, AddExtraRequestLogData
  end

  def remove_existing_log_subscriptions
    ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
      case subscriber
      when ActionController::Base
      when ActionView::LogSubscriber
        unsubscribe(:action_view, subscriber)
      when ActionController::LogSubscriber
        unsubscribe(:action_controller, subscriber)
      end
    end
  end

  def unsubscribe(component, subscriber)
    events = subscriber.public_methods(false).reject { |method| method.to_s == 'call' }
    events.each do |event|
      ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
        if listener.instance_variable_get('@delegate') == subscriber
          ActiveSupport::Notifications.unsubscribe listener
        end
      end
    end
  end
end
