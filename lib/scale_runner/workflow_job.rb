module ScaleRunner
  class WorkflowJob
    attr_accessor :labels, :run_id, :name, :repository, :repository_url
    def initialize(params)
      params["workflow_job"].tap do |job|
        @run_id = job["run_id"]
        @status = job["status"]
        @name = job["name"]
        @labels = job["labels"]
      end
      params["repository"].tap do |repo|
        @repository = repo["full_name"]
        @repository_url = repo["html_url"]
      end
    end

    def queued?
      @status.eql?("queued")
    end

    def in_progress?
      @status.eql?("in_progress")
    end

    def completed?
      @status.eql?("completed")
    end
  end
end