# -*- encoding : utf-8 -*-

require_relative "../spec_helper.rb"

describe RecordMailer do
  before(:each) do
    allow(RecordMailer).to receive(:default) { { :from => 'no-reply@projectblacklight.org' } }
    SolrDocument.use_extension( Blacklight::Document::Email )
    SolrDocument.use_extension( Blacklight::Solr::Document::Sms )
    document = SolrDocument.new({:id=>"123456", :format=>["book"], :title_display => "The horn", :language_facet => "English", :author_display => "Janetzky, Kurt"})
    @documents = [document]
  end
  describe "email" do
    before(:each) do
      details = {:to => 'test@test.com', :message => "This is my message"}
      @email = RecordMailer.email_record(@documents,details,{:host =>'projectblacklight.org', :protocol => 'https'}) 
    end
    it "should receive the TO paramater and send the email to that address" do
      expect(@email.to.first).to eq 'test@test.com'
    end
    it "should start the subject w/ Item Record:" do
      expect(@email.subject).to match /^From University of Alberta Libraries: The horn/
    end
    it "should put the title of the item in the subject" do
      expect(@email.subject).to match /The horn/
    end
    it "should have the correct from address (w/o the port number)" do
      expect(@email.from.first).to eq "no-reply@ualberta.ca"
    end
    it "should print out the correct body" do
      expect(@email.body).to match /Title: The horn/
      expect(@email.body).to match /Author: Janetzky, Kurt/
      expect(@email.body).to match /projectblacklight.org/
    end
    it "should use https URLs when protocol is set" do
      details = {:to => 'test@test.com', :message => "This is my message"}
      @https_email = RecordMailer.email_record(@documents,details,{:host =>'projectblacklight.org', :protocol => 'https'})
      expect(@https_email.body).to match %r|https://projectblacklight.org/|
    end
  end
  
  describe "SMS" do
    before(:each) do
      details = {:to => '5555555555@txt.att.net'}
      @sms = RecordMailer.sms_record(@documents,details,{:host =>'projectblacklight.org:3000'})
    end
    it "should create the correct TO address for the SMS email" do
      expect(@sms.to.first).to eq '5555555555@txt.att.net'
    end
    it "should not have a subject" do
      expect(@sms.subject).to be_blank
    end
    it "should have the correct from address (w/o the port number)" do
      expect(@sms.from.first).to eq "no-reply@projectblacklight.org"
    end
    it "should print out the correct body" do
      # expect(@sms.body).to match /The horn/ # These two fields have
      # been removed from the SMS functionality (sp).
      # expect(@sms.body).to match /by Janetzky, Kurt/
      expect(@sms.body).to match /projectblacklight.org:3000/      
    end
    it "should use https URL when protocol is set" do
      details = {:to => '5555555555@txt.att.net'}
      @https_sms = RecordMailer.sms_record(@documents,details,{:host =>'projectblacklight.org', :protocol => 'https'})
      expect(@https_sms.body).to match %r|https://projectblacklight.org/|
    end
  end

end
