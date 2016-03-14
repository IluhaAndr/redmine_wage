require_dependency 'wage_time_report_patch'
require_dependency 'wage_time_entry_patch'

Redmine::Plugin.register :redmine_wage do
  name 'Redmine Wage plugin'
  author 'Ilya Andreyuk'
  description 'Add wage to reports'
  version '0.0.1'
  author_url 'https://github.com/IluhaAndr'
end
