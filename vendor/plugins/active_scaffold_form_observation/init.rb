require 'active_scaffold_form_observation'

ActionView::Base.send :include, AsFoFormColumnsFeatures
ActionController::Base.send :include, AsFoActionControllerFeatures
