require_dependency 'redmine/helpers/time_report'

module Wage
  module TimeReportPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        attr_reader :total_wage

        alias_method_chain :run, :wage
      end
    end

    module InstanceMethods

      def run_with_wage
        unless @criteria.empty?
          time_columns = %w(tyear tmonth tweek spent_on)
          @hours = []
          # Patch begin
          columns = @criteria.collect{|criteria| @available_criteria[criteria][:sql]} + time_columns
          sql = @scope.select("#{columns.join(', ')}, SUM(hours) as hours", "SUM(hours * coalesce(custom_values.value, 0) ) as wage").
            eager_load(user: { custom_values: :custom_field }).where("custom_fields.name = 'Rate' OR custom_fields.id IS NULL").
            includes(:issue, :activity).group(columns).
            joins(@criteria.collect{|criteria| @available_criteria[criteria][:joins]}.compact).to_sql
          ActiveRecord::Base.connection.select_rows(sql).map{ |row|
              [ row.first(columns.size), row[columns.size], row[columns.size + 1] ] }.
              each do |hash, hours, wage|
            h = {'hours' => hours, 'wage' => wage}
          # Patch end
            (@criteria + time_columns).each_with_index do |name, i|
              h[name] = hash[i]
            end
            @hours << h
          end

          @hours.each do |row|
            case @columns
            when 'year'
              row['year'] = row['tyear']
            when 'month'
              row['month'] = "#{row['tyear']}-#{row['tmonth']}"
            when 'week'
              row['week'] = "#{row['spent_on'].cwyear}-#{row['tweek']}"
            when 'day'
              row['day'] = "#{row['spent_on']}"
            end
          end

          min = @hours.collect {|row| row['spent_on']}.min
          @from = min ? min.to_date : Date.today

          max = @hours.collect {|row| row['spent_on']}.max
          @to = max ? max.to_date : Date.today

          @total_hours = @hours.inject(0) {|s,k| s = s + k['hours'].to_f}
          # Patch begin
          @total_wage = @hours.inject(0) {|s,k| s = s + k['wage'].to_f}
          # Patch end

          @periods = []
          # Date#at_beginning_of_ not supported in Rails 1.2.x
          date_from = @from.to_time
          # 100 columns max
          while date_from <= @to.to_time && @periods.length < 100
            case @columns
            when 'year'
              @periods << "#{date_from.year}"
              date_from = (date_from + 1.year).at_beginning_of_year
            when 'month'
              @periods << "#{date_from.year}-#{date_from.month}"
              date_from = (date_from + 1.month).at_beginning_of_month
            when 'week'
              @periods << "#{date_from.to_date.cwyear}-#{date_from.to_date.cweek}"
              date_from = (date_from + 7.day).at_beginning_of_week
            when 'day'
              @periods << "#{date_from.to_date}"
              date_from = date_from + 1.day
            end
          end
        end
      end

    end

  end
end

Redmine::Helpers::TimeReport.send(:include, Wage::TimeReportPatch)
