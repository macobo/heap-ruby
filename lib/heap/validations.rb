# Internal methods used to validate API input.

class HeapAPI::Client
  # Makes sure that the client's app_id property is set.
  #
  # @raise RuntimeError if the client's app_id is nil
  # @return [HeapAPI::Client] self
  def ensure_valid_app_id!
    raise RuntimeError, 'Heap app_id not set' unless @app_id
    self
  end
  private :ensure_valid_app_id!

  # Validates a Heap server-side API event name.
  #
  # @param [String] event the name of the server-side event
  # @raise ArgumentError if the event name is invalid
  # @return [HeapAPI::Client] self
  def ensure_valid_event_name!(event)
    raise ArgumentError, 'Missing or empty event name' if event.empty?
    raise ArgumentError, 'Event name too long' if event.length > 1024
    self
  end
  private :ensure_valid_event_name!

  # Validates a bag of properties sent to a Heap server-side API.
  #
  # @param [Hash<String, String|Number>] properties key-value property bag;
  #   each key must have fewer than 1024 characters; each value must be a
  #   Number or String with fewer than 1024 characters
  # @raise ArgumentError if the property bag is invalid
  # @return [HeapAPI::Client] self
  def ensure_valid_properties!(properties)
    unless properties.respond_to?(:each)
      raise ArgumentError, 'Properties object does not implement #each'
    end

    properties.each do |key, value|
      if key.to_s.length > 1024
        raise ArgumentError, "Property name #{key} too long; " +
            "#{key.to_s.length} is above the 1024-character limit"
      end
      if value.kind_of? Numeric
        # TODO(pwnall): Check numerical limits, if necessary.
      elsif value.kind_of?(String) || value.kind_of?(Symbol)
        if value.to_s.length > 1024
          raise ArgumentError, "Property #{key} value #{value.inspect} too " +
              "long; #{value.to_s.length} is above the 1024-character limit"
        end
      else
        raise ArgumentError,
            "Unsupported type for property #{key} value #{value.inspect}"
      end
    end
  end
  private :ensure_valid_properties!
end
