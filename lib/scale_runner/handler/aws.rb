module ScaleRunner
  module Handler
    class Aws < Default
      def handle_workflow_queued
        launch_self_hosted_runner
      end

      def handle_workflow_completed
        destroy_self_hosted_runner
      end

      def ami_tag_filters(ami_tags)
        ami_tags.map do |tag|
          tag_name, tag_value = tag.split(':')
          { name: "tag:#{tag_name}", values: tag_value.split(',') }
        end
      end

      def encoded_user_data
        config = Rails.configuration.scale_runner[@config_key]
        runner_name = config[:runner_name] || "ephemeral-runner-#{SecureRandom.hex}"
        runner_scope = config[:runner_scope] || @workflow_job.repository
        template = ERB.new(File.read("#{__dir__}/../template/aws_user_data.erb"))
        script = template.result_with_hash(
          runner_name: runner_name,
          runner_url: @workflow_job.repository_url,
          runner_token: generate_runner_token(runner_scope),
          runner_labels: @workflow_job.labels.join(",")
        )
        encoded_script = Base64.encode64(script)
      end

      def launch_self_hosted_runner
        config = Rails.configuration.scale_runner[@config_key]
        client = ::Aws::EC2::Client.new(region: config[:region])
        ami_id = if config[:ami_id]
                   config[:ami_id]
                 else
                   desc_images = client.describe_images({
                     filters: ami_tag_filters(config[:ami_tags])
                   })
                   desc_images.images.sort_by{ |img| Date.parse(img.creation_date) }.first.image_id
                 end
        resp = client.run_instances({
          block_device_mappings: [
            {
              device_name: config[:device_name], 
              ebs: {
                volume_size: config[:volume_size],
              }, 
            }, 
          ], 
          image_id: ami_id, 
          instance_type: config[:instance_type], 
          key_name: config[:key_name], 
          security_group_ids: config[:security_group_ids], 
          subnet_id: config[:subnet_id],
          max_count: 1,
          min_count: 1,
          user_data: encoded_user_data,
          iam_instance_profile: {
            name: config[:profile_name],
          },
          tag_specifications: [
            {
              resource_type: "instance", 
              tags: [
                {
                  key: "Name", 
                  value: "Ephemeral Runner", 
                },
                {
                  key: "OwnerContact", 
                  value: "gscho", 
                },
                {
                  key: "run_id", 
                  value: @workflow_job.run_id.to_s, 
                },
                {
                  key: "job_name", 
                  value: @workflow_job.name, 
                },
                {
                  key: "repository", 
                  value: @workflow_job.repository, 
                }
              ]
            }
          ]
        })
        VirtualMachine.create(external_id: resp.instances[0].instance_id, workflow_job_run_id: @workflow_job.run_id)
      end

      def destroy_self_hosted_runner
        config = Rails.configuration.scale_runner[@config_key]
        client = ::Aws::EC2::Client.new(region: config[:region])
        vm = VirtualMachine.find_by(workflow_job_run_id: @workflow_job.run_id)
        client.terminate_instances({
          instance_ids: [vm.external_id]
        })
      end
    end
  end
end