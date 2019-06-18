class Company < ApplicationRecord
  require 'csv'
  require 'fileutils'

  has_many :employees, dependent: :destroy
  validates :name, presence: true

  def self.import_employees(company_id, file)
    company = Company.find_by(id: company_id.to_i)
    emp_manager_hash = {}
    total_record = 0
    saved_record = 0
    invalid_record = 0
    
    CSV.foreach(file.path, :headers => true) do |row|
      total_record += 1
      invalid_record += 1 and next if row[1].blank?
      employee_exist = Employee.find_by(email: row[1].to_s)
      next if employee_exist.present?

      @employee = Employee.find_or_create_by(email: row[1].to_s, name: row[0].to_s, company_id: company.id, phone: row[2].to_s)
      # set reporting manager
      if row[3].present?
        report_manager = Employee.find_by(email: row[3].to_s, company_id: company.id)
        if report_manager.present?
          @employee.parent_id = report_manager.id
        else
          emp_manager_hash[@employee.id.to_i] = { email: row[3].to_s, company_id: company.id }
        end
      end
      saved_record += 1
      @employee.save

      # set policy details
      if row[4].present?
        policy_names = row[4].split('|')
        policy_names.each do |p|
          pname = p.try(:downcase)
          policy = Policy.find_or_create_by(name: pname, company_id: company.id)
          unless @employee.policies.include?(policy)
            @employee.policies << policy
          end
        end
      end
    end

    if emp_manager_hash.present?
      emp_manager_hash.each do |key, value|
        employee = Employee.find_by(id: key)
        if employee.present?
          manager_id = Employee.find_by(email: value[:email], company_id: value[:company_id]).try(:id)
          employee.parent_id = manager_id
          employee.save
        end
      end
    end
    return total_record, saved_record, invalid_record
  end
end
