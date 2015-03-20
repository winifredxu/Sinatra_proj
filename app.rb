require "sinatra"
require "pony"  # Pony gem is for sending email

# get is the HTTP protocol used
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