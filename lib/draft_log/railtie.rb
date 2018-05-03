module DraftLog
  class Railtie < Rails::Railtie

    config.after_initialize do |app|
      DraftLog.setup
      ActionController::Base.send :prepend, AddExtraRequestLogData
      DraftLog::ActiveRecordLogSubscriber.attach_to :active_record
    end

    DraftLog::LogSubscriber.attach_to :action_controller
    DraftLog::ViewLogSubscriber.attach_to :action_view
  end
end
