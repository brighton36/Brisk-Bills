class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table( :settings) do |t|
      t.string :keyname, :label
      t.text :keyval, :description

      t.timestamps
    end    
    
    [
      ['company_name',     'Company Name',      'The name of your business',            'ACME Widgets'],
      ['company_url',      'Company URL',       'The address of your website',          'http://localhost'],
      ['company_address1', 'Company Address 1', 'The address of your business, line 1', '1234 5th St.'],
      ['company_address2', 'Company Address 2', 'The address of your business, line 2', 'Suite 100'],
      ['company_city',     'Company City',      'The city your business resides in', 'New York'],
      ['company_state',    'Company State',     'The state your business resides in', 'NY'],
      ['company_zip',      'Company Zip',       'The zip code your business resides in', '55555'],
      ['company_phone',    'Company Phone',     'The main phone line of your business', '555-555-5555'],
      ['company_fax',      'Company Fax',       'The main fax line of your business', '555-555-5555'],
      ['company_logo_file','Company Logo File', 'The filename of your company logo. This file should be a JPG, located in your public/images folder.', 'dti-logo.jpg'],

      ['site_admin_email', 'Site Admin E-mail', 'An e-mail address to send system notifications to', 'root@localhost'],
      ['site_admin_name',  'Site Admin Name',   'The person to send system notifications to',        'Root'],
      ['bcc_invoices_to',  'Bcc Invoices To',   'A BCC line of recipients for invoices genration emails', 'root@localhost'],

      ['slimtimer_dont_autoassign_tasks',  'SlimTimer Task Auto-assign Ignore', 'Don\'t automatically assign a client to any tasks that match this regular expression', '/^(walk in|web lead|dti)$/i'],
      ['slimtimer_dont_autoassign_clients', 'SlimTimer Client Auto-assign Ignore', 'Don\'t automatically assign any clients whose company names match this regular expression', '/^DeRose Technologies, Inc\.$/i'],
      ['slimtimer_sync_from_days_ago',     'SlimTimer Sync Tasks From',         'How many days prior, to keep in sync with the database', '30'],
      ['slimtimer_ignore_tasks',           'SlimTimer Ignore Tasks',            'Ignore time entries with tasks that match this regular expression', '/^(in|out|lunch|Day Off|off)$/i']
      
    ].each do |s| 
      Setting.create(
        :keyname     => (s.length > 0) ? s[0] : nil,
        :label       => (s.length > 1) ? s[1] : nil,
        :description => (s.length > 2) ? s[2] : nil,
        :keyval      => (s.length > 3) ? s[3] : nil
      )
    end
    
  end

  def self.down
    drop_table :settings
  end
end
