module Wage
  module TimeEntryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods

      def wage
        field = user.available_custom_fields.find { |c_f| c_f.name == "Rate" }
        user.custom_field_value(field).to_f * hours
      end

    end

  end
end

TimeEntry.send(:include, Wage::TimeEntryPatch)
