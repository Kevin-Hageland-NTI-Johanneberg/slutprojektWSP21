require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'
require 'byebug'

enable :sessions

get('/') do
    slim(:index)
end

get('/showlogin') do
    slim(:"users/login")
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE username = ?', username).first
    pwdigest = result['pwdigest']
    id = result['id']
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:username] = username
      redirect('/browse')
    else
      "Fel lösenord >:("
    end
end

get('/showregister') do
    slim(:"users/register")
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
 
  if (password == password_confirm) #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    db.execute("INSERT INTO users (username,pwdigest,money) VALUES (?,?,0)", username, password_digest)
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    id = result['id'] # Hör med emil varför detta ger error???
    session[:username] = username
    session[:id] = id
    redirect("/browse")
  else #felhantering
    "Lösenordet matchade inte!"
  end
end

get('/browse') do
    slim(:"posts/index")
end

get('/business/:id') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  db.results_as_hash = true

  business = db.execute("SELECT businesses.name
  FROM ((user_to_business 
    INNER JOIN users ON user_to_business.user_id = users.id)
    INNER JOIN businesses ON user_to_business.user_id = user_id)
    WHERE users.id = ?", id) #range error
  session[:businesses] = business
  slim(:"management/businesses")
end

get('/account/:id') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  db.results_as_hash = true

  business = db.execute("SELECT businesses.id, businesses.name, businesses.money
  FROM ((user_to_business 
    INNER JOIN users ON user_to_business.user_id = users.id)
    INNER JOIN businesses ON user_to_business.user_id = user_id)
    WHERE users.id = ?", id) #range error
  slim(:"management/user", locals:{businesses:business})
end

post('/add_money') do #business id, look how
  id = session[:id].to_i
  money_to_add = params[:money_to_add].to_i
  user_money = db.execute('SELECT money FROM users WHERE id = ?', id)
  if user_money > money_to_add
    current_money = db.execute('SELECT money FROM businesses WHERE id = ?', business_id)
  else
    print "Oops, something went wrong!"
  end
end