module Admin::ActivitiesHelper
    
  def proposal_proposed_on_form_column(record, input_name)
    # Super-ghetto hack
    @proposal = record.proposal

    input(:proposal,'proposed_on').gsub(/proposal(\[proposed_on\([\d]+i\)\])/m, 'record\1')
    #/Super Ghetto
  end
  
end