module DraftLog
  module AddExtraRequestLogData
    def append_info_to_payload(payload)
      super
      payload[:query_string] = request.query_parameters
      payload[:params] = request.params.except(:controller, :action)
      payload[:cookies] = cookies.to_h.select{|x| !x.ends_with?("_session") }
      payload[:session] = session.to_hash.select{|x| ["session_id", "_csrf_token"].exclude?(x) }
      payload[:path_param] = request.path_parameters.except(:controller, :action, :format, :_method, :only_path)
      payload[:controller_instance_var] = instance_variables.select{|x| !x.to_s.start_with?('@_') }.reject{|y| y == :@marked_for_same_origin_verification }.
        inject({}) {|result, element| result[element.to_s] = instance_variable_get(element.to_s).to_s; result }
    end
  end
end
