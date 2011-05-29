module Admin::ActivitiesHelper
    
  def activity_proposed_on_form_column(record, options)
    # Super-ghetto hack
    @proposal = record.proposal

    input(:proposal,'proposed_on').gsub(/proposal(\[proposed_on\([\d]+i\)\])/m, 'record\1')
    #/Super Ghetto
  end
  
end