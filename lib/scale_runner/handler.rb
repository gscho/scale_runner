require_relative "handler/default"
require_relative "handler/aws"

module ScaleRunner
  module Handler
    def self.process_event(params)
      workflow_job = WorkflowJob.new(params)
      config_key = workflow_job.labels.join('_')
      puts config_key
      handler_type = Rails.configuration.scale_runner[config_key][:type].capitalize
      handler = "ScaleRunner::Handler::#{handler_type}".constantize.new
      puts handler.class
      handler.run(workflow_job, config_key)
    end
  end
end