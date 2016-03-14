require_dependency 'redmine/helpers/time_report'

module Wage
  module TimeEntryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods

      def wage
        field = available_custom_fields.find { |c_f| c_f.name == "Rate" }
        custom_field_value(field).to_f * hours
      end

    end

  end
end

TimeEntry.send(:include, Wage::TimeEntryPatch)
