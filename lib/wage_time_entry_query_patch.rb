module Wage
  module TimeEntryQueryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.available_columns << QueryColumn.new(:wage)

      base.class_eval do
        attr_reader :total_wage

        alias_method_chain :default_columns_names, :wage
      end
    end

    module InstanceMethods

      def default_columns_names_with_wage
        default_columns_names_without_wage << :wage
      end

    end

  end
end

TimeEntryQuery.send(:include, Wage::TimeEntryQueryPatch)


