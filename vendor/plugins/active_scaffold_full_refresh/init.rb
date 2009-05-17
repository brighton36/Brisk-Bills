require 'active_scaffold_full_refresh'

ActiveScaffold::Config::Base.send :attr_accessor, :full_list_refresh_on

ActiveScaffold::Actions::Create.send :include, ActiveScaffoldFullRefresh
ActiveScaffold::Actions::Update.send :include, ActiveScaffoldFullRefresh
ActiveScaffold::Actions::Delete.send :include, ActiveScaffoldFullRefresh
