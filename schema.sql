-- Users Table
CREATE TABLE Users (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_picture_url VARCHAR(500) DEFAULT 'https://picsum.photos/100',
    bio TEXT,
    account_creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_date TIMESTAMP,
    account_status ENUM('ACTIVE', 'SUSPENDED', 'DELETED') DEFAULT 'ACTIVE',
    is_verified BOOLEAN DEFAULT FALSE,
    INDEX idx_user_email (email),
    INDEX idx_user_username (username)
) PARTITION BY HASH(user_id) PARTITIONS 16;

-- User Roles Table
CREATE TABLE UserRoles (
    user_id BIGINT,
    role ENUM('USER', 'ADMIN', 'MODERATOR') DEFAULT 'USER',
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    PRIMARY KEY (user_id, role)
);

-- User Preferences Table
CREATE TABLE UserPreferences (
    user_id BIGINT PRIMARY KEY,
    language VARCHAR(10),
    theme ENUM('LIGHT', 'DARK', 'SYSTEM') DEFAULT 'SYSTEM',
    privacy_level ENUM('PUBLIC', 'PRIVATE', 'FRIENDS_ONLY') DEFAULT 'PUBLIC',
    notification_settings JSON,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);