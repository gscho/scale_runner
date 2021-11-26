class CreateVirtualMachines < ActiveRecord::Migration[6.1]
  def change
    create_table :virtual_machines do |t|
      t.string :external_id
      t.integer :workflow_job_run_id
      t.string :workflow_job_repository

      t.timestamps
    end
  end
end
