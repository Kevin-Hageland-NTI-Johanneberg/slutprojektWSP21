require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'

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
      redirect('/browse')
    else
      "Fel lösenord >:("
    end
end

get('/showregister') do
    slim(:register)
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  if (password == password_confirm) #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.execute("INSERT INTO users (username,pwdigest,money) VALUES (?,?,0)", username, password_digest)
    redirect("/browse")
  else #felhantering
    "Lösenordet matchade inte!"
  end
end

get('/browse') do
    slim(:"posts/browse")
end

