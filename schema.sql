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

-- Posts Table
CREATE TABLE Posts (
    post_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    content TEXT,
    post_type ENUM('TEXT', 'IMAGE', 'VIDEO', 'LINK') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    visibility ENUM('PUBLIC', 'PRIVATE', 'FRIENDS_ONLY') DEFAULT 'PUBLIC',
    like_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    share_count INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    INDEX idx_post_user (user_id),
    INDEX idx_post_created_at (created_at)
) PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p0 VALUES LESS THAN (UNIX_TIMESTAMP('2023-01-01')),
    PARTITION p1 VALUES LESS THAN (UNIX_TIMESTAMP('2024-01-01')),
    PARTITION p2 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01')),
    PARTITION p3 VALUES LESS THAN MAXVALUE
);

-- Media Table
CREATE TABLE Media (
    media_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT,
    user_id BIGINT NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_type ENUM('IMAGE', 'VIDEO') NOT NULL,
    file_size BIGINT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    INDEX idx_media_post (post_id)
);