module Admin::ProposalsHelper
  include Admin::ActivityTypeFieldHelper
  
  alias :activity_proposal_tax_column :tax_column
  alias :activity_proposal_cost_column :cost_column
  
  alias :activity_proposal_occurred_on_form_column :occurred_on_form_column
  alias :activity_proposal_client_form_column :client_form_column
  alias :activity_proposal_cost_form_column :cost_form_column
  
  alias :activity_proposal_tax_form_column :tax_form_column
  alias :activity_proposal_comments_form_column :comments_form_column 
end
