module WmsInstrumentation
  class LogSubscriber < ActiveSupport::LogSubscriber
    def wms(event)
      return unless logger.info?
      name = '%s (%.1fms)' % ["WMS Dispatch", event.duration]
      info "#{color(name, GREEN, true)} Map: #{event.payload[:map_id]} - #{event.payload[:status]}"
    end
  end
end
WmsInstrumentation::LogSubscriber.attach_to :dispatch