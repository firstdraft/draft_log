require "active_record/log_subscriber"

module DraftLog
  class ActiveRecordLogSubscriber < ::ActiveRecord::LogSubscriber


    def sql(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      payload = event.payload

      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

      name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      name  = "CACHE #{name}" if payload[:cached]
      sql   = payload[:sql]
      binds = nil

      unless (payload[:binds] || []).empty?
        casted_params = type_casted_binds(payload[:binds], payload[:type_casted_binds])
        binds = "  " + payload[:binds].zip(casted_params).map { |attr, value|
          render_bind(attr, value)
        }.inspect
      end

      name = colorize_payload_name(name, payload[:name])
      sql  = color(sql, sql_color(sql), true)
      
      Thread.current[:active_record_log_payload] ||= []
      Thread.current[:active_record_log_payload] << "  #{name}  #{sql}#{binds}"
    end

    private

      def type_casted_binds(binds, casted_binds)
        casted_binds || ActiveRecord::Base.connection.type_casted_binds(binds)
      end
    
  end
end
