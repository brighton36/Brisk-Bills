module Admin::ActivityTaxControllerHelper

  def on_tax_observation
    render(:update) do |page|
      begin
        tax_percent, tax_flat = Setting.grab :sales_tax_percent, :sales_tax_flat

        tax_percent = tax_percent.to_f
        tax_flat = tax_flat.to_f

        id_suffix = (params[:eid] ? '_' : '')+params[:record_id]
        
        tax_field_id  = options_for_column(:tax)[:id] + id_suffix
        cost_field_id = options_for_column(:cost)[:id] + id_suffix
        tax_field_hidden_id  = "%s_hidden"  % tax_field_id

        page[cost_field_id].value = money_for_input(params[:cost].to_f)

        if params['apply_tax'] == 'yes'
          # Calculate the new auto-tax amount here...
          page[tax_field_id].value = money_for_input(params[:cost].to_f * (tax_percent/100) + tax_flat)

          # Now enable the control:          
          page[tax_field_id].enable
          page[tax_field_hidden_id].disable
          page[tax_field_id].removeClassName "disabled"
        else
          page[tax_field_id].value = ''
          page[tax_field_id].disable
          page[tax_field_hidden_id].enable
          page[tax_field_id].addClassName "disabled"
        end

      rescue
        page.alert 'Error updating form Record(%s) "%s"' % [params[:record_id], $!]
      end
    end
  end

  def self.append_features(base)
    super

    base.class_eval do
      observe_active_scaffold_form_fields :fields => %w(apply_tax cost), :for_activities => 'material', :action => :on_tax_observation
    end
  end

end