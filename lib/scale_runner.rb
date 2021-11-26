require "aws-sdk-ec2"
require "erb"
require "json"
require "net/http"
require "securerandom"
require "uri"

require_relative "scale_runner/handler"
require_relative "scale_runner/version"
require_relative "scale_runner/workflow_job"

module ScaleRunner; end