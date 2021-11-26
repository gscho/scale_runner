Rails.application.routes.draw do
  post "/scale-runner", to: "workflow_job_event#webhook"
end
