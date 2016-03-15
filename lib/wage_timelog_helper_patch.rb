require_dependency 'redmine/helpers/time_report'

module Wage
  module TimelogHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :report_to_csv, :wage
        alias_method_chain :report_criteria_to_csv, :wage
      end
    end

    module InstanceMethods

      def report_to_csv_with_wage(report)
        decimal_separator = l(:general_csv_decimal_separator)
        export = CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
          # Column headers
          headers = report.criteria.collect {|criteria| l(report.available_criteria[criteria][:label]) }
          headers += report.periods
          headers << l(:label_total_time)
          # Patch begin
          headers << l(:field_wage)
          # Patch end
          csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(
                                        c.to_s,
                                        l(:general_csv_encoding) ) }
          # Content
          report_criteria_to_csv(csv, report.available_criteria, report.columns, report.criteria, report.periods, report.hours)
          # Total row
          str_total = Redmine::CodesetUtil.from_utf8(l(:label_total_time), l(:general_csv_encoding))
          row = [ str_total ] + [''] * (report.criteria.size - 1)
          total = 0
          # Patch begin
          total_wage = 0
          # Patch end
          report.periods.each do |period|
            # Patch begin
            hours = select_hours(report.hours, report.columns, period.to_s)
            sum = sum_hours(hours)
            # Patch end
            total += sum
            row << (sum > 0 ? ("%.2f" % sum).gsub('.',decimal_separator) : '')
            # Patch begin
            total_wage += hours.inject(0) { |sum, h| sum + h['wage'].to_f }
            # Patch end
          end
          row << ("%.2f" % total).gsub('.',decimal_separator)
          # Patch begin
          row << ("%.2f" % total_wage).gsub('.',decimal_separator)
          # Patch end
          csv << row
        end
        export
      end

      def report_criteria_to_csv_with_wage(csv, available_criteria, columns, criteria, periods, hours, level=0)
        decimal_separator = l(:general_csv_decimal_separator)
        hours.collect {|h| h[criteria[level]].to_s}.uniq.each do |value|
          hours_for_value = select_hours(hours, criteria[level], value)
          next if hours_for_value.empty?
          row = [''] * level
          row << Redmine::CodesetUtil.from_utf8(
                            format_criteria_value(available_criteria[criteria[level]], value).to_s,
                            l(:general_csv_encoding) )
          row += [''] * (criteria.length - level - 1)
          total = 0
          # Patch begin
          total_wage = 0
          # Patch end
          periods.each do |period|
            # Patch begin
            selected_hours = select_hours(hours_for_value, columns, period.to_s)
            sum = sum_hours(selected_hours)
            # Patch end
            total += sum
            row << (sum > 0 ? ("%.2f" % sum).gsub('.',decimal_separator) : '')
            # Patch begin
            total_wage += selected_hours.inject(0) { |sum, h| sum + h['wage'].to_f }
            # Patch end
          end
          row << ("%.2f" % total).gsub('.',decimal_separator)
          # Patch begin
          row << ("%.2f" % total_wage).gsub('.',decimal_separator)
          # Patch end
          csv << row
          if criteria.length > level + 1
            report_criteria_to_csv(csv, available_criteria, columns, criteria, periods, hours_for_value, level + 1)
          end
        end
      end

    end

  end
end

TimelogHelper.send(:include, Wage::TimelogHelperPatch)
