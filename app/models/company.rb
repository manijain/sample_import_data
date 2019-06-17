class Company < ApplicationRecord
  require 'csv'
  require 'fileutils'

  has_many :employees
  validates :name, presence: true

  def self.import_employees(company_id, file)
    company = Company.find_by(id: company_id.to_i)
    CSV.foreach(file.path, :headers => true) do |row|
      @employee = Employee.find_or_create_by(email: row[1].to_s, name: row[0].to_s, company_id: company.id)
      # set reporting manager
      if row[3].present?
        report_manager = Employee.find_by(email: row[3].to_s)
        @employee.parent_id = report_manager.id if report_manager.present?
      end
      @employee.phone = row[2].to_s if row[2].present?
      @employee.save

      # set policy details
      if row[4].present?
        policy_names = row[4].split('|')
        policy_names.each do |p|
          pname = p.try(:downcase)
          policy = Policy.find_or_create_by(name: pname, company_id: company.id)
          unless @employee.policies.include?(policy)
            @employee.policies << policy
            @employee.save
          end
        end
      end
    end
  end
end
