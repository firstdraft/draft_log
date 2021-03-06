require "active_support"

module DraftLog
  class LogSubscriber < ActiveSupport::LogSubscriber

    def process_action(event)
      payload = event.payload
      param_method = payload[:params]["_method"]
      method = param_method ? param_method.upcase : payload[:method]
      
      message = %Q{\nWe received a request at #{Time.now.strftime("%I:%M%p on %A, %b %d!")} Someone wants to
  #{method} #{payload[:path]}

The route told me to use the #{payload[:controller].ai} and #{payload[:action].ai} action.\n\n}

      message += flexible_path_segment(payload) if payload[:path_param].present?
      message += custom_query_string(payload) if payload[:query_string].present?
      message += custom_params(payload) if payload[:params].present?
      # message += custom_cookies(payload) if payload[:cookies].present?
      # message += custom_session(payload) if payload[:session].present?
      message += activerecord_sql(payload) if payload[:active_record_log_payload].present?
      message += custom_instance_var(payload) if payload[:controller_instance_var].present?
      message += view_log(payload) if payload[:view_log_event_data].present?
      message += completed_message(event)
      message += "========================================\n"

      logger.warn message
    end

    private

    def flexible_path_segment(payload)
      "I found these inputs in flexible path segments:
#{payload[:path_param].ai}\n\n"
    end

    def custom_query_string(payload)
      "I found these inputs in the query string:
#{payload[:query_string].ai}\n\n"
    end

    def custom_params(payload)
      "The final params hash containing all inputs looks like this:
  # params
#{payload[:params].ai}\n\n"
    end

    def custom_cookies(payload)
      "Here are the cookies that came along with the request:
  # cookies
#{payload[:cookies].ai}\n\n"
    end

    def custom_session(payload)
      "  # session
#{payload[:session].ai}\n\n"
    end

    def activerecord_sql(payload)
      msg = "Query\n"
      msg += payload[:active_record_log_payload].join("\n") + "\n\n"
      msg
    end

    def custom_instance_var(payload)
      %Q{The #{(payload[:controller] + '#' +payload[:action]).ai} action defined these instance variables:
#{payload[:controller_instance_var].ai}\n\n}
    end

    def view_log(payload)
      template_path = payload[:view_log_event_data][:identifier].sub("#{Rails.root.to_s}/", '')
      %Q{The #{(payload[:controller] + "#" + payload[:action]).ai} action told me to use
  #{template_path.ai}
to format the response.\n\n}
    end

    def completed_message(event)
      payload   = event.payload
      additions = ActionController::Base.log_process_action(payload)

      status = payload[:status]
      if status.nil? && payload[:exception].present?
        exception_class_name = payload[:exception].first
        status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)
      end

      message = "Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in #{event.duration.round}ms"
      message << " (#{additions.join(" | ".freeze)})" unless additions.empty?
      message << "\n\n" if defined?(Rails.env) && Rails.env.development?

      message
    end

  end
end
