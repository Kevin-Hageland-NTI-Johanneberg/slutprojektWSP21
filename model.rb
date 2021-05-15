require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './app.rb'
require 'byebug'


module Model
    
    # Tries to log in the user
    #
    # @param [String] username, the username
    # @param [String] password, tha password
    #
    # @return [Hash]
    #   * :error [Boolean] whether an error occured
    #   * :message [String] the error message
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

    # Registers a user
    #
    # @param [String] username, the username
    # @param [String] password, the password
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
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

    # The names from the businesses of current user
    #
    # @param [Integer] id, the id of the current user
    #
    # @return [Hash] containing the business data 
    def get_businesses_from_user(id)
        db = SQLite3::Database.new('db/online-investor.db')
        db.results_as_hash = true
    
        business = db.execute("SELECT businesses.name
        FROM (user_to_business 
        INNER JOIN businesses ON user_to_business.business_id = businesses.id)
        WHERE user_id = ?", id) # if this fucked up, return it by yoinking the code 2 rows below
        return business
    end 
    
    # Creates a post with data from the user
    #
    # @param [Integer] business_id, the id of the business creating the post
    # @param [String] title, the title of the post
    # @param [String] picture, a picture of the invention # might not be a string depending on how I make it work lol
    # @param [String] body, the description of the invention
    # @param [Integer] money_offer, the amount of money the user wants
    # @param [Integer] percent_offer, the percentage the user gives to the buyer for that money
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def create_post(business_id, title, picture, body, money_offer, percent_offer)
        db = SQLite3::Database.new('db/online-investor.db')
        db.execute("INSERT INTO posts (business_id, title, picture, content, money_offer, percent_offer) VALUES (?, ?, ?, ?, ?, ?)", business_id, title, picture, body, money_offer, percent_offer)  
        return
    end

    # The id, name and money data from the businesses of current user
    #
    # @param [String] username, the username
    # @param [String] password, the password
    #
    # @return [Hash] containing the business data 
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

    # Changes the username of the user by updating the database
    #
    # @param [Integer] id, the id of the current user
    # @param [String] username, the username the user wants to swap to
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def change_username(id, username)
        db = SQLite3::Database.new('db/online-investor.db')
        db.execute("UPDATE users SET username = ? WHERE id = ?", username, id).first
        return
    end

    # Changes the password of the user by updating the database
    #
    # @param [Integer] id, the id of the current user
    # @param [String] password, the password the user wants to swap to
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def change_password(id, password)
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/online-investor.db')
        db.results_as_hash = true
        db.execute("UPDATE users SET pwdigest = ? WHERE id = ?", password_digest, id)
        return
    end

    # Looking at the users current money
    #
    # @param [Integer] id, the id of the current user
    # @param [Integer] money, the money the user want to add
    #
    # @return [Integer] of the users money
        def account_money(id)
            db = SQLite3::Database.new('db/online-investor.db')
            user_money = db.execute('SELECT money FROM users WHERE id = ?', user_id).first.first
            return user_money
        end      

    # Adding money to the current user by adding it onto what the user has and then updating the database
    #
    # @param [Integer] id, the id of the current user
    # @param [Integer] money, the money the user want to add
    # @see Model#account_money
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def add_account_money(id, money)
        db = SQLite3::Database.new('db/online-investor.db')
        current_money = account_money(id)
        total_money = current_money + money
        db.execute('UPDATE users SET money = ? WHERE id = ?', total_money, id)  
        return
    end

    # Adding money to a business by adding it onto what the business has and subtracting that from the user, then updating the database
    #
    # @param [Integer] business_id, the id of the business
    # @param [Integer] user_id, the id of the current user
    # @param [Integer] money_to_add, the money the user want to add
    # @see Model#account_money
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def add_business_money(business_id, user_id, money_to_add)
        current_money = db.execute("SELECT money FROM businesses WHERE id = ?", business_id).first.first
        total_money = current_money + money_to_add
        user_money = account_money(user_id)
        user_money -= money_to_add
        db.execute('UPDATE businesses SET money = ? WHERE id = ?', total_money, business_id)
        db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, user_id)
        return
    end

    # Leave a business by removing the user from the business in user_to_business table
    #
    # @param [Integer] business_id, the id of the business
    # @param [Integer] user_id, the id of the current user
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def leave_business(user_id, business_id)
        db = SQLite3::Database.new('db/online-investor.db')
        db.execute("DELETE FROM user_to_business WHERE business_id = ? AND user_id = ?", business_id, user_id).first
        return
    end  

    # Join a business by inserting the id of the user into the user_to_business that got that specific business name
    #
    # @param [Integer] id, the id of the current user
    # @param [String] business_name, the name of the business the user wants to join
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def join_business(id, business_name)
        db = SQLite3::Database.new('db/online-investor.db')
        business_id = db.execute("SELECT id FROM businesses WHERE name = ?", business_name) # fixa felhantering
        db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", id, business_id)
        session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first.first
        return true
    end

    # User creates a business by inserting data into business table and user_to_business
    #
    # @param [Integer] user_id, the id of the current user
    # @param [Integer] user_money, the balance of the user
    # @param [String] name, the name of the business
    # @param [Integer] budget, the starting budget of the business
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
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

    # Delete a user by removing them from multiple tables
    #
    # @param [Integer] id, the id of the current user
    #
    # @return [Hash]
        #   * :error [Boolean] whether an error occured
        #   * :message [String] the error message
    def delete_user(id)
        db = SQLite3::Database.new('db/online-investor.db')
        db.execute('DELETE FROM users WHERE id = ?', id)
        session[:id] = nil
        return
    end
end