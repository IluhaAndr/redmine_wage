require_dependency 'redmine/helpers/time_report'

module Wage
  module TimeEntryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_create :set_rate
      end
    end

    module InstanceMethods

      def set_rate
        field = available_custom_fields.find { |c_f| c_f.name == "Rate" }
        self.rate = custom_field_value(field).to_f
      end

      def wage
        rate * hours
      end

    end

  end
end

TimeEntry.send(:include, Wage::TimeEntryPatch)
