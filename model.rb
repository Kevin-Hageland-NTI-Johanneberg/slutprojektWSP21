require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './app.rb'
require 'byebug'

def logged_in?(username, password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE username = ?', username).first
    pwdigest = result['pwdigest']
    id = result['id']
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:username] = username
      business_id = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first
      session[:business_id] = business_id["business_id"]
      return true
    else
      return false
    end
end

def register_user(username, password)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    db.execute("INSERT INTO users (username,pwdigest,money) VALUES (?,?,0)", username, password_digest)
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    id = result['id']
    session[:username] = username
    session[:id] = id
    session[:business_id] = nil
    return
end

def get_businesses_from_user(id)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
  
    business = db.execute("SELECT businesses.id, businesses.name, businesses.money
    FROM (user_to_business 
      INNER JOIN businesses ON user_to_business.business_id = businesses.id)
      WHERE user_id = ?", id)
    return business
end 

def create_post(business_id, title, picture, body, money_offer, percent_offer)
    db = SQLite3::Database.new('db/online-investor.db')
    db.execute("INSERT INTO posts (business_id, title, content, money_offer, percent_offer) VALUES (?, ?, ?, ?, ?)", business_id, title, body, money_offer, percent_offer)  
    return
end

def get_user_business_data(id)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    user_data = db.execute("SELECT * FROM users WHERE id = ?", id).first
    session[:username] = user_data["username"]
    session[:money] = user_data["money"]
  
    business = db.execute("SELECT businesses.id, businesses.name, businesses.money
    FROM (user_to_business 
      INNER JOIN businesses ON user_to_business.business_id = businesses.id)
      WHERE user_id = ?", id)
    return business
end

def change_username(id, username)
    db = SQLite3::Database.new('db/online-investor.db')
    db.execute("UPDATE users SET username = ? WHERE id = ?", username, id).first
    return
end

def change_password(id, password)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    db.execute("UPDATE users SET pwdigest = ? WHERE id = ?", password_digest, id)
    return
end

def add_account_money(id, money)
    db = SQLite3::Database.new('db/online-investor.db')
    current_money = db.execute("SELECT money FROM users WHERE id = ?", id).first.first
    total_money = current_money + money
    db.execute('UPDATE users SET money = ? WHERE id = ?', total_money, id)  
    return
end

def account_money(id)
    db = SQLite3::Database.new('db/online-investor.db')
    user_money = db.execute('SELECT money FROM users WHERE id = ?', user_id).first.first
    return user_money
end  

def add_business_money(id, money_to_add)
    current_money = db.execute("SELECT money FROM businesses WHERE id = ?", id).first.first
    total_money = current_money + money_to_add
    user_money -= money_to_add
    db.execute('UPDATE businesses SET money = ? WHERE id = ?', total_money, id)
    db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, user_id)
    return
end

def leave_business(user_id, business_id)
    db = SQLite3::Database.new('db/online-investor.db')
    db.execute("DELETE FROM user_to_business WHERE business_id = ? AND user_id = ?", business_id, user_id).first
    return
end  

def join_business(id, business_name)
    db = SQLite3::Database.new('db/online-investor.db')
    business_id = db.execute("SELECT id FROM businesses WHERE name = ?", business_name) # fixa felhantering
    db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", id, business_id)
    session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first.first
    return true
end

def create_business(user_id, user_money, name, budget)
    db = SQLite3::Database.new('db/online-investor.db')
    user_money -= starting_budget
    db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, user_id)

    db.execute("INSERT INTO businesses (name, money) VALUES (?, ?)", name, budget)
    business_id = db.execute("SELECT id FROM businesses WHERE name = ?", name).first.first
    db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", user_id, business_id)
    session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", user_id).first.first
    return
end