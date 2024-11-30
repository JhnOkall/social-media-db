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

-- Comments Table (with recursive self-join for threaded comments)
CREATE TABLE Comments (
    comment_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    parent_comment_id BIGINT,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    like_count INT DEFAULT 0,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (parent_comment_id) REFERENCES Comments(comment_id) ON DELETE CASCADE,
    INDEX idx_comment_post (post_id),
    INDEX idx_comment_parent (parent_comment_id)
) PARTITION BY HASH(post_id) PARTITIONS 16;

-- Likes Table
CREATE TABLE Likes (
    like_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    content_id BIGINT NOT NULL,
    content_type ENUM('POST', 'COMMENT') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_like (user_id, content_id, content_type),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    INDEX idx_like_user (user_id),
    INDEX idx_like_content (content_id, content_type)
);

-- Followers Table
CREATE TABLE Followers (
    follower_id BIGINT NOT NULL,
    followed_id BIGINT NOT NULL,
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    FOREIGN KEY (follower_id) REFERENCES Users(user_id),
    FOREIGN KEY (followed_id) REFERENCES Users(user_id),
    INDEX idx_followers_follower (follower_id),
    INDEX idx_followers_followed (followed_id)
);

-- Message Threads Table
CREATE TABLE MessageThreads (
    thread_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    thread_type ENUM('PRIVATE', 'GROUP') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP
);

-- Message Thread Participants
CREATE TABLE MessageThreadParticipants (
    thread_id BIGINT,
    user_id BIGINT,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (thread_id, user_id),
    FOREIGN KEY (thread_id) REFERENCES MessageThreads(thread_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Messages Table
CREATE TABLE Messages (
    message_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    thread_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_status ENUM('SENT', 'DELIVERED', 'READ') DEFAULT 'SENT',
    FOREIGN KEY (thread_id) REFERENCES MessageThreads(thread_id),
    FOREIGN KEY (sender_id) REFERENCES Users(user_id),
    INDEX idx_message_thread (thread_id),
    INDEX idx_message_sender (sender_id)
) PARTITION BY HASH(thread_id) PARTITIONS 16;

-- Notifications Table
CREATE TABLE Notifications (
    notification_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    sender_id BIGINT,
    notification_type ENUM('LIKE', 'COMMENT', 'FOLLOW', 'MENTION', 'MESSAGE') NOT NULL,
    content_id BIGINT,
    content_type ENUM('POST', 'COMMENT', 'MESSAGE') DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (sender_id) REFERENCES Users(user_id),
    INDEX idx_notification_user (user_id),
    INDEX idx_notification_type (notification_type)
);