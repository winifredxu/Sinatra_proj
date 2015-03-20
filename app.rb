require "sinatra"
require "pony"  # Pony gem is for sending email
require "data_mapper"

# use SqlLite db, file name is current directory/data.db
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/data.db")

# Defining the class for our ORM, this will create a table named "contacts"
class Contact

  # include a module from DataMapper to inject the functionality of DM into this class
  include DataMapper::Resource

  # Property will definne an attr accessor with the name of symbol that's passed. It will correspond to a column in the contacts table created by the class.

  property :id, Serial # Serial will be: INTEGER PRIMARY KEY AUTOINCREMENT
  property :name, String #String: VARCHAR(50) -> used for small text
  property :email, String
  property :msg, Text #Text: VARCHAR with no limit of chars
  property :note, Text

end

# create the contact table if doesn't exist, with the columns defined as properties above. If the table already exist, it will add only the columns that are not added.
# remove column will not work, change to property will also get updated.
Contact.auto_upgrade!

# this enables us to have patch and delete if we send a parameter called _method with value "patch" or "delete"
use Rack::MethodOverride


#copied over from "http://www.sinatrarb.com/faq.html#auth"
helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end


# routes in Sinatra

get '/' do
  "Everybody can see this page"
end

get '/protected' do
  protected!
  "Welcome, authenticated client"
end

# get -> is the HTTP protocol used
# "/" refers to the URL -> in this case this is the homepage
# "Hello! Welcome to CodeCore!" -> this is the response
get "/" do
  @name = params[:name]
    # by convention, render the views/index.erb file
  erb :index, layout: :application
end

# format to pass in params in the URL use:  "?" and "&"
# http://l#ocalhost:4567/about?name=Tam&city=Vancouver&country=Canada
# then the params hash will be something like:
# {name: "Tam", city: "Vancouver", country: "Canada"}
get "/about" do
  "About Us - Welcome to our website. #{params[:name]}, you are from #{params[:city]}, #{params[:country]}."
end

get "/contact" do
  erb :contact_form, layout: :application
end

post "/contact" do
  #"Thanks for contacting us!"
  # params.to_s

  # store the contact info into the SqlLite DB
  # c = Contact.new({
  Contact.create({
      name: params[:full_name], 
      email: params[:user_email], 
      msg: params[:message]
    })

  Pony.mail({
    :to => 'winnielandau@gmail.com',
    subject: "#{params[:full_name]} has sent you a message",
    body: "email:#{params[:user_email]} Message: #{params[:message]}",
    :via => :smtp,
    :via_options => {
      :address        => 'smtp.gmail.com',
      :port           => '587',
      :user_name      => 'answerawesome',
      :password       => 'Sup3r$ecret',
      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain         => "gmail.com" # the HELO domain provided by the client to the server
    }
  })

  erb :thankyou, layout: :application

end

get "/all_contacts" do

  protected!

  # this will fetch all the contacts records from the DB, query used will be like:
  # SELECT * FROM contacts;
  @contacts = Contact.all
  erb :all_contacts, layout: :application
end

get "/contact/:id" do |id|
  protected!

  @contact = Contact.get(id)
  erb :contact, layout: :application
end

patch "/contact/:id" do |id|
  protected!

  contact = Contact.get(id)
  contact.note = params[:note]
  contact.save

  #params.to_s   #show all the params
  redirect to("/contact/#{id}")
end

delete "/contact/:id" do |id|
  protected!

  contact = Contact.get(id)
  contact.destroy

  redirect to("/all_contacts")
end