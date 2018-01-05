module DraftLog
  class Railtie < Rails::Railtie

    config.after_initialize do |app|
      DraftLog.setup
      ActionController::Base.send :prepend, AddExtraRequestLogData
    end

    DraftLog::LogSubscriber.attach_to :action_controller
  end
end
