module ScaleRunner
  module Handler
    class Default      
      def run(workflow_job, config_key)
        @workflow_job = workflow_job
        @config_key = config_key
        if @workflow_job.queued?
          handle_workflow_queued
        elsif @workflow_job.completed?
          handle_workflow_completed
        else
          # no op
        end
      end

      fail "Must suppy a RUNNER_CFG_PAT environment variable" unless ENV["RUNNER_CFG_PAT"]

      def generate_runner_token(runner_scope)
        api_url = ENV["GITHUB_API_URL"] || "https://api.github.com"
        repos_or_orgs = runner_scope.split("/").size > 1 ? "repos" : "orgs"
        github_api_url = "#{api_url}/#{repos_or_orgs}"
        
        uri = URI.parse("#{github_api_url}/#{runner_scope}/actions/runners/registration-token")
        request = Net::HTTP::Post.new(uri)
        request["accept"] = "application/vnd.github.everest-preview+json"
        request["authorization"] = "token #{ENV["RUNNER_CFG_PAT"]}"

        req_options = { use_ssl: uri.scheme == "https" }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        json = JSON.parse response.body
        json["token"]
      end

      def handle_workflow_queued; end

      def handle_workflow_completed; end
    end
  end
end