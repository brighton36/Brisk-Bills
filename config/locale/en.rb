{
  :'en' => {
    :time => {
      :formats => {
        :default => '%m/%d/%y %l:%M%P'
      }
    },
    
    :salt_is_missing => "Salt is missing - No Salt is a bad idea!",
    
    :invoice_outstanding_details => 'for Invoice #{{inv_id}} ({{issued_on}}). Currently outstanding: {{amount_outstanding}}',
    :enter_a_payment_amount => '(Enter a Payment Amount)',
    :no_outstanding_invoices_for_account => 'There are no outstanding invoices on this account.',
    :choose_a_client => '(Choose a Client)',
    :payment_method_identifier_description => 'Last four card digits, check number...',
    
    :first_time_setup_welcome => "\nWelcome to Brisk Bills!\nWhat follows is your first-time setup 'wizard'. This task, if successful, will test your database, run your migrations, and create your first employee log-in account. To ensure success,  hit 'y' when you don't understand a question.",
    :first_time_setup_confirm_env => "\nI see we're running in the #{RAILS_ENV.inspect} environment, with the following settings:",
    :first_time_setup_confirm_env_prompt => "Is this the database environment and configuration you wish to create/use? (Y/N) : ",
    :first_time_setup_user_abort => "\nNo problem! Go ahead and edit the '#{RAILS_ROOT}/config/database.yml' file to match your preference, and re-run this task.\nIf you don't like running in the #{RAILS_ENV.inspect} environment, then run this task with the appropriate RAILS_ENV parameter.",
    :first_time_setup_empty_pass => "\nYour password is empty! That doesn't look right... You want to stop and adjust this? (Y/N) : ",
    :first_time_setup_connection_fail => "\nUnable to connect to the database server. This could be because:\n  * The specified connection/database settings are wrong.\n  * The specified database/username does not exist on the SQL server.\n\nPlease verify the contents of your 'config/database.yml' file.\nOr, if you have access to the database server, run the following SQL commands to create the database and user:\n  {{sql}}",
    :first_time_setup_run_migration_prompt => "\nNo tables found in database - Run Migrations? (Y/N) : ",
    :first_time_setup_migration_complete => "\nMigrations Completed Successfully!",
    :first_time_setup_create_first_employee => "\nNo employees found in database. Create a first employee? (Y/N) : ",
    :first_time_setup_employee_enter => "\nPlease enter your first employee's information...",
    :first_time_setup_first_name => 'First Name',
    :first_time_setup_last_name => 'Last Name',
    :first_time_setup_email => 'E-mail Address',
    :first_time_setup_password => 'Password',
    :first_time_setup_first_employee_msg => "\nAre you sure you would like to create the following user?",
    :first_time_setup_first_employee_confirm => 'Proceed ? (Y/N) : ',
    :first_time_setup_complete => "\nFirst time setup is now complete. To get started, run ./script/server and head to http://localhost:3000 to begin using brisk bills. Be sure to log-in with your newly created first-employee credentials."
  }
}