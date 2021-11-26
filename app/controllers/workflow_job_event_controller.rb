class WorkflowJobEventController < ApplicationController
  def webhook
    ScaleRunner::Handler.process_event params
  end
end
